#!/usr/bin/perl

#GERA OS CONTEXTOS, AS PALAVRAS E AS FREQUENCIAS USANDO UM FICHEIRO DE PALAVRAS FILTRADAS
#lê o resultado do parsing: dependencias.

#use progs::funcoes::categorias
use File::Path qw( make_path );

$file = shift(@ARGV);
open( FILE, $file ) or die "O ficheiro nao pode ser aberto: $!\n";

while ( $words = <FILE> ) {
    chomp $words;
    $Words{$words}++;

}

$CountDep = 0;

$directories = "tmp/freqs";
if ( !-d $directories ) {
    make_path $directories or die "Failed to create path: $directories";
}

my %NPN   = ();
my %NPV   = ();
my %VPN   = ();
my %VPV   = ();
my %APN   = ();
my %APV   = ();
my %NN    = ();
my %NA    = ();
my %AN    = ();
my %RA    = ();
my %RV    = ();
my %VR    = ();
my %VAmod = ();
my %VVmod = ();
my %VN    = ();
my %NV    = ();
my %DVV   = ();
my %SVV   = ();

open my $NPN,   '>', $directories . "/" . "NPN";
open my $NPV,   '>', $directories . "/" . "NPV";
open my $VPN,   '>', $directories . "/" . "VPN";
open my $VPV,   '>', $directories . "/" . "VPV";
open my $APN,   '>', $directories . "/" . "APN";
open my $APV,   '>', $directories . "/" . "APV";
open my $NN,    '>', $directories . "/" . "NN";
open my $NA,    '>', $directories . "/" . "NA";
open my $AN,    '>', $directories . "/" . "AN";
open my $RA,    '>', $directories . "/" . "RA";
open my $RV,    '>', $directories . "/" . "RV";
open my $VR,    '>', $directories . "/" . "VR";
open my $VAmod, '>', $directories . "/" . "VAmod";
open my $VVmod, '>', $directories . "/" . "VVmod";
open my $VN,    '>', $directories . "/" . "VN";
open my $NV,    '>', $directories . "/" . "NV";
open my $DVV,   '>', $directories . "/" . "DVV";
open my $SVV,   '>', $directories . "/" . "SVV";

while ( $line = <STDIN> ) {

    if ( $line !~ /^SENT::/ ) {

        if ( ( $CountLines % 100 ) == 0 ) {
            ;
            printf STDERR "- - - processar linha:(%6d) - - -\r", $CountLines;
        }
        $CountLines++;

        $rel   = "";
        $head  = "";
        $dep   = "";
        $cat_h = "";
        $cat_d = "";
        $cat_r = "";

        chop($line);

        #tiramos as parenteses da dependencia
        $line =~ s/^\(//;
        $line =~ s/\)$//;

        # print STDERR "$line\n";

        $line =~ s/^(Circ|[iI]obj|Creg)/iobj/;

        ( $rel, $head, $dep ) = split( '\;', $line );

        ( $head, $cat_h ) = split( "_", $head );
        ( $dep,  $cat_d ) = split( "_", $dep );

        ##Filtering
        $w1 = $head . "_" . $cat_h;
        $w2 = $dep . "_" . $cat_d;

        #     print STDERR "w1 : #$w1# -- w2: #$w2#\n";
        #     if (!$Words{$w1} || !$Words{$w2})
        if ( !$Words{$w1} && !$Words{$w2} ) {

            #	 print STDERR "w1 : #$w1# -- w2: #$w2#\n";
            next;
        }

        if ( $rel =~ /_/ ) {
            ( $rel,     $cat_r ) = split( "_",  $rel );
            ( $relname, $rel )   = split( '\/', $rel );

            #print STDERR "REL::: $rel -- $cat_r\n";
        }

##REGRA  NOUN-PREP-NOUN

        if (   ( $cat_r =~ /^PRP|POS/ )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $rel . $; . $dep . "\n" ), $NPN );
        }

##REGRA  NOUN-PREP-VERB                                                                                                                                                        i
        if (   ( $cat_r =~ /^PRP|POS/ )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^V/ ) )
        {
            writeFile( ( $head . $; . $rel . $; . $dep . "\n" ), $NPV );
        }

##REGRA  VERB-PREP-NOUN

        elsif (( $cat_r =~ /^PRP/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $rel . $; . $dep . "\n" ), $VPN );

            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";
        }

##REGRA  VERB-PREP-VERB
        elsif (( $cat_r =~ /^PRP/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^V/ ) )
        {
            writeFile( ( $head . $; . $rel . $; . $dep . "\n" ), $VPV );

            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";
        }

##REGRA  ADJ-PREP-NOUN
        elsif (( $cat_r =~ /^PRP/ )
            && ( $cat_h =~ /^ADJ/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $rel . $; . $dep . "\n" ), $APN );

            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";
        }
        ##REGRA  ADJ-PREP-VERB
        elsif (( $cat_r =~ /^PRP/ )
            && ( $cat_h =~ /^ADJ/ )
            && ( $cat_d =~ /^V/ ) )
        {
            writeFile( ( $head . $; . $rel . $; . $dep . "\n" ), $APV );

            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";
        }

##REGRA  NOUN-NOUN (linguas romances)

        elsif (( $rel eq "AdjnR" )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $NN );
        }

##REGRA  NOUN-NOUN (ingles)

        elsif (( $rel eq "AdjnL" )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $NN );
        }

##REGRAS NOUN-ADJ, ADJ-NOUN

        elsif (( $rel eq "AdjnR" )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^ADJ/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $NA );
        }

        elsif (( $rel eq "AdjnL" )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^ADJ/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $AN );
        }
        ##se o dependente e um cardinal, colocar a etiqueta para reduzir o numero de contextos diferentes
        elsif (( $rel eq "AdjnL" )
            && ( $cat_h =~ /^N/ )
            && ( $cat_d =~ /^CARD/ ) )
        {
            writeFile( ( $head . $; . $cat_d . "\n" ), $AN );
        }

##REGRA  ADV-ADJ (Adjn)
        elsif (( $rel =~ /^AdjnL/ )
            && ( $cat_h =~ /^ADJ/ )
            && ( $cat_d =~ /^ADV/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $RA );
        }

        #REGRA  ADV-VERB (AdjnL)
        elsif (( $rel =~ /^AdjnL/ )
            && ( $cat_h =~ /^VERB/ )
            && ( $cat_d =~ /^ADV/ ) )
        {
            $RV{ $head, $dep }++;
            writeFile( ( $head . $; . $dep . "\n" ), $RV );
        }

        #REGRA  VERB-ADV (AdjnR)
        elsif (( $rel =~ /^AdjnR/ )
            && ( $cat_h =~ /^VERB/ )
            && ( $cat_d =~ /^ADV/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $VR );
        }

##REGRA  VERB-ADJ (Atr)
        elsif (( $rel =~ /^Atr/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^ADJ/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $VAmod );
        }

##REGRA  VERB-VERB (Adjn)
        elsif (( $rel =~ /^Adjn/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^V/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $VVmod );
        }

##REGRA  VERB-NOUN

        elsif (( $rel =~ /^(Dobj|Atr)/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $VN );
        }

##REGRA  NOUN-VERB

        elsif (( $rel =~ /^Subj/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^N/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $NV );
        }

        ##REGRA  VERB-VERB (Dobj)
        elsif (( $rel =~ /^(Dobj|Atr)/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^V/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $DVV );
        }
        ##REGRA  VERB-VERB (Subj)
        elsif (( $rel =~ /^Subj/ )
            && ( $cat_h =~ /^V/ )
            && ( $cat_d =~ /^V/ ) )
        {
            writeFile( ( $head . $; . $dep . "\n" ), $SVV );
        }

    }

}

sub writeFile {
    my $text = shift(@_);
    my $fh   = shift(@_);

    print $fh $text;
}

print STDERR
  "fim leitura do ficheiro de entrada -- hashes carregados em memoria\n";

close $NPN;
close $NPV;
close $VPN;
close $VPV;
close $APN;
close $APV;
close $NN;
close $NA;
close $AN;
close $RA;
close $RV;
close $VR;
close $VAmod;
close $VVmod;
close $VN;
close $NV;
close $DVV;
close $SVV;

open my $NPN, '<', $directories . "/" . "NPN";
printContextos( $NPN, "Cprep&", "3" );
close $NPN;

open my $NPV, '<', $directories . "/" . "NPV";
printContextos( $NPV, "CprepV&", "3" );
close $NPV;

open my $VPN, '<', $directories . "/" . "VPN";
printContextos( $VPN, "Iobj&", "3" );
close $VPN;

open my $VPV, '<', $directories . "/" . "VPV";
printContextos( $VPV, "IobjV&", "3" );
close $VPV;

open my $APN, '<', $directories . "/" . "APN";
printContextos( $APN, "Aprep&", "3" );
close $APN;

open my $APV, '<', $directories . "/" . "APV";
printContextos( $APV, "AprepV&", "3" );
my $a = keys %AN;

print STDERR "\n" . $a . "\n";
close $APV;

open my $NN, '<', $directories . "/" . "NN";
printContextos( $NN, "modN", "2" );
close $NN;

open my $NA, '<', $directories . "/" . "NA";
printContextos( $NA, "Rmod", "2" );
close $NA;

open my $AN, '<', $directories . "/" . "AN";
printContextos( $AN, "Lmod", "2" );
close $AN;

open my $RA, '<', $directories . "/" . "RA";
printContextos( $RA, "LmodA", "2" );
close $RA;

open my $RV, '<', $directories . "/" . "RV";
printContextos( $RV, "LmodV", "2" );
close $RV;

open my $VR, '<', $directories . "/" . "VR";
printContextos( $VR, "RmodV", "2" );
close $VR;

open my $VAmod, '<', $directories . "/" . "VAmod";
printContextos( $VAmod, "Vmod", "2" );
close $Vamod;

open my $VVmod, '<', $directories . "/" . "VVmod";
printContextos( $VVmod, "VmodV", "2" );
close $VVmod;

open my $VN, '<', $directories . "/" . "VN";
printContextos( $VN, "Dobj", "2" );
close $VN;

open my $NV, '<', $directories . "/" . "NV";
printContextos( $NV, "Subj", "2" );
close $NV;

open my $DVV, '<', $directories . "/" . "DVV";
printContextos( $DVV, "DobjV", "2" );
close $DVV;

open my $SVV, '<', $directories . "/" . "SVV";
printContextos( $SVV, "SubjV", "2" );
close $SVV;

sub printContextos {
    my $fh     = shift(@_);
    my $prefix = shift(@_);
    my $tipo   = shift(@_);
    my %counter;

    while ( my $line = <$fh> ) {
        $counter{$line}++;
    }

    if ( $tipo == "3" ) {
        while ( my ( $k, $v ) = each %counter ) {
            my ( $p1, $p2, $p3 ) = split( /$;/o, $k );

            chomp $p3;

            printf "%s%s_down_%s %s %d\n", $prefix, $p2, $p1, $p3, $v;
            printf "%s%s_up_%s %s %d\n",   $prefix, $p2, $p3, $p1, $v;
        }
    }
    else {
        while ( my ( $k, $v ) = each %counter ) {
            my ( $p1, $p2 ) = split( /$;/o, $k );

            chomp $p2;

            printf "%s_down_%s %s %d\n", $prefix, $p1, $p2, $v;
            printf "%s_up_%s %s %d\n",   $prefix, $p2, $p1, $v;
        }
    }
}
