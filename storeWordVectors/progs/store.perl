#!/usr/bin/perl

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use utf8;
use open qw(:std :utf8);
use strict;

use Storable qw(store retrieve freeze thaw dclone);
use Time::HiRes qw( time );
use threads;

my $dir = shift(@ARGV);
my $LING = shift(@ARGV);
my $output = shift(@ARGV);
my $th=100;

my %Dico;
my %Trad;
my %Cntx;
while (my $line = <STDIN>) {
 chomp $line;
 my ($cntx_bil, $word, $freq) = split (" ", $line); 

 $cntx_bil =~ s/iobj&/iobj\//g;
 if ($word !~ /\#${LING}$/) {next} ##só palavras inglesas pois imos construir vectores em ingles
 $Dico{$word}{$cntx_bil} = $freq;
 
 my ($cntx1, $cntx2) = split (";", $cntx_bil);
 $Trad{$cntx1}{$cntx2}++ if ($dir eq "s");
 $Trad{$cntx2}{$cntx1}++ if ($dir eq "t");
 $Cntx{$cntx_bil}{$word} = $freq;
}

store [\%Dico, \%Trad, \%Cntx],  $output;


my $start;
my $end = time();
printf STDERR ("Loading time: %.4f\n", $end - $start);

 


