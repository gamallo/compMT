#!/usr/bin/env perl
use LWP::Simple;
use URI::Encode qw(uri_encode uri_decode);
use URI::Escape;


use strict;
##

my $stFiles = "/home/ivan/CiTIUS/compmtAPI/lib/resources/";
our $validateFileBase = $stFiles . "validation/";
my $rankingResults  = "";
my $validationFile  = $validateFileBase . "golden-en-es-1.csv";
my $validationFileT = $validationFile . "_tagged";
my $validationFileV = $validationFile . "_validated";
my $posCounter      = 0;
my $negCounter      = 0;

open my $infoTT, $validationFileT  or die "Could not open $validationFileT: $!";
open my $infoV, '>', $validationFileV
  or die "Could not open $validationFileV: $!";

my @lines = ();

while ( my $line = <$infoTT> ) {

    # get rid of \r\n
    $line =~ s/\R//g;

    # If current line is the separator, then translate the content of @lines
    if ( $line eq "*********************" ) {
        my $text   = shift(@lines);
        my $verbs  = shift(@lines);
        my $tagged = join "\n", @lines;

        # Get translation

        my $url = "http://localhost:4000/translatetagged/" . uri_escape($text) . "/tagged/" . uri_escape($tagged);

        print $url;
        print "\n-----------------------\n";

        my $content = get($url);

        print $infoV ($content. "\t" .$verbs . "\t" . $text."\n");
        print STDERR ($posCounter+$negCounter)." examples translated\n";

        @lines = ();
    }
    # Else, add current line to the batch
    else {
       print STDERR "step -> $line\n";
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

print "Validation results were stored in <b>$validationFileV</b>\n";
