#!/usr/bin/perl


use threads;
use Thread::Queue 3.01 qw( );

use constant NUM_WORKERS    => 3;
use constant WORK_UNIT_SIZE => 100000;


$file = shift(@ARGV);
open (FILE, $file) or die "O ficheiro nom pode ser aberto: $!\n";


$debug=1;

while (<STDIN>) {
    $line = $_;
    chomp $line;
    
    
    ($cntx, $word, $freq) = split(/ /, $line);
    
    #  $cntxWord{$cntx}{$word}=$freq;
    $cntxFreq{$cntx} += $freq;
    $wordFreq{$word} += $freq;
    
    $Diff{$cntx}++;
    
    $totalFreq += $freq;
    
    printf STDERR "<%7d>\r",$cont if ($cont++ % 2500 == 0);
    
}

$N = $totalFreq;




sub worker {
    $file = "temporal_ivan_".threads->tid();
    open ($fich, ">".$file) or die "O ficheiro temporal non pode ser creado: $!\n";
    
    my ($job) = @_;
    for (@$job) {
        $line = $_;
        chomp $line;
        
        ($cntx, $word, $freq) = split(/ /, $line);
        
        
        #$a = $cntxWord{$cntx}{$word};
        $a = $freq;
        $b = $cntxFreq{$cntx} - $a;
        $c = $wordFreq{$word} - $a;
        $d = $N - $a - $b -$c;
        
        printf STDERR "<%7d>\r",$cont if ($cont-- % 2500 == 0);
        
        $baux = ($b==0)?0:($b*log($b));
        $caux = ($c==0)?0:($c*log($c));
        
        $llike = $a*log($a)             +
        $baux                  +
        $caux                  +
        $d*log($d)             +
        $N*log($N)             -
        ($a+$c)*log($a+$c)     -
        ($a+$b)*log($a+$b)     -
        ($b+$d)*log($b+$d)     -
        ($c+$d)*log($c+$d);
        
        
        $llike = $llike / $Diff{$cntx};
        #     printf STDERR  "%s %s n=%d a=%d b=%d c=%d d=%d llike=%f\n",$cntx, $word, $N, $a, $b, $c, $d, $llike if ($debug);
        printf $fich "%s %s %f\n",$cntx, $word, $llike;
    }
    
    close($fich);
}


my $q = Thread::Queue->new(); #::any

async { while (defined( my $job = $q->dequeue() )) { worker($job); } }
for 1..NUM_WORKERS;

my $done = 0;    
while (!$done) {
    my @lines;
    while (@lines < WORK_UNIT_SIZE) {
        my $line = <FILE>;
        if (!defined($line)) {
            $done = 1;
            last;
        }
        
        push @lines, $line;
    }
    
    $q->enqueue(\@lines) if @lines;
}

$q->end();
$_->join for threads->list; 
