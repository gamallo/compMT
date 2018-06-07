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

my $CORE_COUNT = 4;
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


# Fragementamos os hashes para gardalos usando threads (Unha division por core)
my $DicoSize = (scalar keys %Dico) / $CORE_COUNT;
my $TradSize = (scalar keys %Trad) / $CORE_COUNT;
my $CntxSize = (scalar keys %Cntx) / $CORE_COUNT;

my %Dico1 = (%Dico)[0 .. (2*$DicoSize - 1)];
my %Dico2 = (%Dico)[(2*$DicoSize - 1) .. 2*(2*$DicoSize - 1)];
my %Dico3 = (%Dico)[2*(2*$DicoSize - 1) .. 3*(2*$DicoSize - 1)];
my %Dico4 = (%Dico)[3*(2*$DicoSize - 1) .. 4*(2*$DicoSize - 1)];

my %Trad1 = (%Trad)[0 .. (2*$TradSize - 1)];
my %Trad2 = (%Trad)[(2*$TradSize - 1) .. 2*(2*$TradSize - 1)];
my %Trad3 = (%Trad)[2*(2*$TradSize - 1) .. 3*(2*$TradSize - 1)];
my %Trad4 = (%Trad)[3*(2*$TradSize - 1) .. 4*(2*$TradSize - 1)];

my %Cntx1 = (%Cntx)[0 .. (2*$CntxSize - 1)];
my %Cntx2 = (%Cntx)[(2*$CntxSize - 1) .. 2*(2*$CntxSize - 1)];
my %Cntx3 = (%Cntx)[2*(2*$CntxSize - 1) .. 3*(2*$CntxSize - 1)];
my %Cntx4 = (%Cntx)[3*(2*$CntxSize - 1) .. 4*(2*$CntxSize - 1)];


threads->create(sub {
    my $tid = threads->tid();
    store [\%Dico1, \%Cntx1, \%Trad1],  "$output-$tid";
});

threads->create(sub {
    my $tid = threads->tid();
    store [\%Dico2, \%Cntx2, \%Trad2],  "$output-$tid";
});

threads->create(sub {
    my $tid = threads->tid();
    store [\%Dico3, \%Cntx3, \%Trad3],  "$output-$tid";
});

threads->create(sub {
    my $tid = threads->tid();
    store [\%Dico4, \%Cntx4, \%Trad4],  "$output-$tid";
});



my $running_threads = $CORE_COUNT;
while ($running_threads) {
    for my $thread (threads->list(threads::joinable)) {
        $thread->join();
        $running_threads--;
    }

    sleep 1;
}

my $start;
my $end = time();
printf STDERR ("Loading time: %.4f\n", $end - $start);

 


