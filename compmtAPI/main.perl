#!/usr/bin/env perl
use Dancer2;

set port => config->{port};

use lib::compMT::modules::BuildTarget;
use lib::compMT::modules::Misc;
use lib::compMT::modules::Distances;
use lib::compMT::modules::HeadDep;

binmode STDIN,  ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Clone 'clone';
use utf8;
use open qw(:std :utf8);
use POSIX qw(strftime);
use Storable qw(store retrieve freeze thaw dclone);
use IO::Handle;
use LWP::UserAgent;
use Text::Unidecode;

my $endpoint = config->{endpoint} || "";
my $ua = LWP::UserAgent->new;

our $appname          = config->{appname};
our $lib              = config->{lib};
our $parser           = config->{parser};
our $dicos            = config->{dicos};
our $stFiles          = config->{stFiles};
our $validateFileBase = $stFiles . "validation/";

my $arrayref = retrieve( $stFiles . "verb-en.st" );
my $DicoVE   = $arrayref->[0];
my $TradVE   = $arrayref->[1];
my $CntxVE   = $arrayref->[2];

$arrayref = retrieve( $stFiles . "verb-es.st" );
my $DicoVS = $arrayref->[0];
my $TradVS = $arrayref->[1];
my $CntxVS = $arrayref->[2];

$arrayref = retrieve( $stFiles . "noun-en.st" );
my $DicoNE = $arrayref->[0];
my $TradNE = $arrayref->[1];
my $CntxNE = $arrayref->[2];

$arrayref = retrieve( $stFiles . "noun-es.st" );
my $DicoNS = $arrayref->[0];
my $TradNS = $arrayref->[1];
my $CntxNS = $arrayref->[2];

open( DICCIONARIO, $dicos )
  or die "O ficheiro de dicos non pode ser aberto: $!\n";
my $diccionario = "";
while ( my $line = <DICCIONARIO> ) {
    $diccionario .= $line;
}

plog(now() . "$appname - service loaded\n");

get '/translate/:text' => sub {
    my $parsed         = "";
    my $rankingResults = "";
    my $text           = route_parameters->get('text');

    print STDERR "TEXT INPUT: #$text#\n";
    $parsed = parseText($text);

    plog(now() . "$appname - request: {\"source\": \"$text\"}\n");
    $rankingResults = translateTagged($text, $parsed);

    plog(now() . "$appname - response: $rankingResults\n");

    return $rankingResults;
};

get '/ping' => sub {
    return "pong\n";
};

get '/translatetagged/:text/tagged/:text2' => sub {
    my $rankingResults = "";
    my $text           = route_parameters->get('text');
    my $parsed         = route_parameters->get('text2');

    $rankingResults = translateTagged($text, $parsed);

    return $rankingResults;
};

get '/tag/:text' => sub{
  my $parsed          = "";
  my $validationFile  = $validateFileBase . route_parameters->get('text');
  my $validationFileT = $validationFile . "_tagged";

  # Open the file to validate and it creates the temporal one.
  open my $info, $validationFile or die "Could not open $validationFile: $!";
  open my $infoT, '>', $validationFileT
    or die "Could not open $validationFileT: $!";

  # for each validation line
  while ( my $line = <$info> ) {
      # get rid of \r\n
      $line =~ s/\R//g;

      # split line by columns
      my ( $source, $target, $verbs ) = split( "\t", $line );

      $parsed = parseText($source);

      # store parsed text on temporal file
      print $infoT ( $source . "\n" );
      print $infoT ( $verbs . "\n" );
      print $infoT $parsed;
      print $infoT "*********************\n";
  }

  close $info;
  close $infoT;

  return "Input from <b>$validationFile</b> was parsed and stored on <b>$validationFileT</b> \n";
};

get '/validate/:text' => sub {
    my $rankingResults  = "";
    my $validationFile  = $validateFileBase . route_parameters->get('text');
    my $validationFileT = $validationFile . "_tagged";
    my $validationFileV = $validationFile . "_validated";
    my $posCounter      = 0;
    my $negCounter      = 0;
    my ($infoV, $infoTT);

    open $infoTT, $validationFileT  or die "Could not open $validationFileT: $!";
    open $infoV, '>', $validationFileV
      or die "Could not open $validationFileV: $!";

    $infoV->autoflush(1);
    my @lines = ();

    while ( my $line = <$infoTT> ) {

        # get rid of \r\n
        $line =~ s/\R//g;

        # If current line is the separator, then translate the content of @lines
        if ( $line eq "*********************" ) {
            my $text   = shift(@lines);
            my $verbs  = shift(@lines);
            my $parsed = join "\n", @lines;

            # Get translation
            $rankingResults = translateTagged($text, $parsed);

            @lines = ();

            # Check if the result is correct
            my $result = "";
            if ( isWellTranslated( $verbs, $rankingResults ) ) {
                $posCounter++;
                $result = "pos";
            }
            else {
                $negCounter++;
                $result = "neg";
            }

            print $infoV ($rankingResults. "\t" .$verbs . "\t" . $result."\n");
            print STDERR ($posCounter+$negCounter)." examples translated\n";
        }
        # Else, add current line to the batch
        else {
          # print STDERR "step\n";
            push @lines, $line;
        }

    }

    print $infoV ( "\n\nResume:\nPositives: "
          . $posCounter
          . "\nNegatives: "
          . $negCounter
          . "\n\n" );

    close $infoTT;
    close $infoV;

    return "Validation results were stored in <b>$validationFileV</b>\n";
};

sub isWellTranslated {
    my $verbs = shift(@_);
    my @verbs = split( ",", $verbs );
    my $text = shift(@_);

    my ( $trash,   $trash2 ) = split( "\"target\": \"", $text );
    my ( $content, $trash3 ) = split( "\"}",            $trash2 );

    my $match = 0;
    # print STDERR "------------* $verbs *------------------------\n\n\n";
    for (@verbs) {
      # print STDERR "*******$_********\n\n\n";
        if ( index( lc($content), lc($_) ) != -1 ) {
            $match = 1;
        }
    }
    return $match;
}

sub parseText {
    my $text   = shift(@_);
    $text .= $text =~ /\.$/ ? "" : ".";    #add a final dot if has any
    $text = substr( $text, 0, ( index( $text, '.' ) + 1 ) );

    if($endpoint ne "") {
        my $input = '{"text" : "'.unidecode($text).'"}';
        my $response = $ua->post($endpoint, Content => $input);
        if ($response->is_success) {
            my $result = from_json($response->decoded_content);
            return join("\n", @{$result->{"parsed"}}) . "\n";
        }
    }

    # Fallback to local parser
    return `/bin/bash  $parser  "$text"`;
}

sub translateTagged {
    my $DicoHE;
    my $TradHE;
    my $CntxHE;
    my $DicoHS;
    my $TradHS;
    my $CntxHS;
    my $DicoTE;
    my $TradTE;
    my $CntxTE;
    my $DicoTS;
    my $TradTS;
    my $CntxTS;
    my @target         = ("");
    my @sHead          = ("");
    my @tHead          = ("");
    my @sDep           = ("");
    my @tDep           = ("");
    my @fr             = ("");
    my @pares          = ();
    my @result         = ("");
    my $currentIndex   = 0;
    my $nextIndex      = 1;
    my $text           = shift(@_);
    my @input          = ();
    my $rankingResults = "";

    @input = split( "\n", shift(@_) );

    my $newTarget = "";

    foreach (@input) {
        my $line      = $_;
        my @distances = ();
        my ( $currentSHead, $currentTHead, $currentSDep, $currentTDep );

        $newTarget =
          BuildTarget::buildTarget( $diccionario, $target[$currentIndex],
            $result[$currentIndex], $line );

        push @target, $newTarget;

        my $currentPar = Misc::pares( $newTarget, $line );
        push @pares, $currentPar;

        my $root = Misc::root( $line, "head" );

        if ($root eq "verb\n"){
          $DicoHE = $DicoVE;
          $TradHE = $TradVE;
          $CntxHE = $CntxVE;
          $DicoHS = $DicoVS;
          $TradHS = $TradVS;
          $CntxHS = $CntxVS;
        }else{
          $DicoHE = $DicoNE;
          $TradHE = $TradNE;
          $CntxHE = $CntxNE;
          $DicoHS = $DicoNS;
          $TradHS = $TradNS;
          $CntxHS = $CntxNS;
        }

        push @sHead,
          HeadDep::sHead( $sHead[-1], $line, $DicoHE, $TradHE, $CntxHE );

        my @tHeadRes =
          HeadDep::tHead( $target[-1], $tHead[-1], $DicoHS, $TradHS, $CntxHS );
        push @tHead, $tHeadRes[0];
        push @fr,  $tHeadRes[1];

        $root = Misc::root( $line, "dep" );

        if ($root eq "verb\n"){
          $DicoTE = $DicoVE;
          $TradTE = $TradVE;
          $CntxTE = $CntxVE;
          $DicoTS = $DicoVS;
          $TradTS = $TradVS;
          $CntxTS = $CntxVS;
        }else{
          $DicoTE = $DicoNE;
          $TradTE = $TradNE;
          $CntxTE = $CntxNE;
          $DicoTS = $DicoNS;
          $TradTS = $TradNS;
          $CntxTS = $CntxNS;
        }

        push @sDep,
          HeadDep::sDep( $sHead[-1], $line, $DicoTE, $TradTE, $CntxTE );
        my @tDepRes =
          HeadDep::tDep( $target[-1], $tHead[-1], $DicoTS, $TradTS, $CntxTS );
        push @tDep, $tDepRes[0];
        push @fr, (( pop @fr ) . $tDepRes[1]);

        ## simil
        $currentSHead = $sHead[-1];
        $currentTHead = $tHead[-1];
        $currentSDep  = $sDep[-1];
        $currentTDep  = $tDep[-1];
        my $headMerged = $currentSHead . $currentTHead;
        my $depMerged  = $currentSDep . $currentTDep;

        push @distances, Distances::cosineBin( $headMerged, $currentPar );
        push @distances, Distances::jaccard( $headMerged, $currentPar, 1 );
        push @distances, Distances::cosine( $headMerged, $currentPar, 1 );
        push @distances, Distances::diceBin( $headMerged, $currentPar, 1 );

        push @distances, Distances::cosineBin( $depMerged, $currentPar );
        push @distances, Distances::jaccard( $depMerged, $currentPar, 1 );
        push @distances, Distances::cosine( $depMerged, $currentPar, 1 );
        push @distances, Distances::diceBin( $depMerged, $currentPar, 1 );

        my $distances = join "\n",
          @distances[ ( $#distances - 7 ) .. $#distances ];
        $distances =~ tr/\n//s;    # Remove blank lines created in previous join

        my $currResult = Misc::similTotalFromChunks( $distances, $line, 50, $fr[-1] );
        push @result, $currResult;

        $currentIndex++;
    }

    my $aux = join "", @result;

    # we want to send a Json so, we prepare the data
    $rankingResults = Misc::toJson( Misc::ranking($aux), $text );

    return $rankingResults;
}

sub plog
{
    my $msg = shift;
    my $facility = "syslog";
    my $severity = "warning";

    open(my $fh, "| logger -p $facility.$severity");
    print $fh $msg;
    close($fh);
}

sub now
{
    return strftime ("%a %b %d %Y - %H:%M", localtime), " ";
}

### Execute the Dancer framework ###
dance;
