#!/usr/bin/perl 


# LE O FICHEIRO COM TODOS OS CONTEXTOS E O FICHEIRO COM TODOS OS TEMPLATES E FILTRA OS TEMPLATES QUE NAO APARECEM NOS CONTEXTOS
#lê um ficheiro com todos os contextos (cntx pal freq) (pipe)
# o argumento é um ficheiro com os templates que vao ser seleccionados (arg)


$file = shift(@ARGV);

$L1= shift(@ARGV);
$L2= shift(@ARGV);

open (INPUT, $file) or die "O ficheiro não pode ser aberto: $!\n";

use threads;
use Thread::Queue 3.01 qw( );

use constant NUM_WORKERS    => 16;
use constant WORK_UNIT_SIZE => 1000000;

my %Cntx :shared = {};

while ($line = <STDIN>) {
    chop($line);
    ($cntx, $pal, $freq, $ling) = split (" ", $line);
    $c1= $cntx . "\#" . $L1;
    $c2= $cntx . "\#" . $L2;
    #print STDERR "$c1 - $c2\n";
    
    $Cntx{$c1}++ ;
    $Cntx{$c2}++ ;
}

sub worker {
    my ($job) = @_;
    for (@$job) {
        $line = $_;
        chop($line);
        ($cntx1, $cntx2, $prob) = split (" ", $line);
        
        if (defined $Cntx{$cntx1} && defined $Cntx{$cntx2}) {
            print "$line\n";
        }
    }
}

my $q = Thread::Queue->new();

async { while (defined( my $job = $q->dequeue() )) { worker($job); } }
for 1..NUM_WORKERS;

my $done = 0;    
while (!$done) {
    my @lines;
    while (@lines < WORK_UNIT_SIZE) {
        my $line = <INPUT>;
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

