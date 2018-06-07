#!/usr/bin/perl 

use threads;
use threads::shared;
use Thread::Queue 3.01 qw( );
use Data::Dumper;
use Thread::Semaphore;

my $mutex = Thread::Semaphore->new();  # Shared by all threads.
STDOUT->autoflush();
STDERR->autoflush();

use constant NUM_WORKERS    => 8;
use constant WORK_UNIT_SIZE => 500000;


#LE O FICHEIRO COM TODOS OS CONTEXTOS E SELECCIONA OS TEMPLATES QUE SERVIRAO PARA FAZER A EXTRACÇAO TESAURICA
#lê um ficheiro com todos os contextos (cntx pal freq) (pipe)
# o argumento é um ficheiro com os templates que vao ser seleccionados (arg)


$file = shift(@ARGV);

$L1= shift(@ARGV);
$L2= shift(@ARGV);

open (INPUT, $file) or die "O ficheiro de seeds não pode ser aberto: $!\n";
#open (OUTPUT, ">bigramas.txt");

$tmp="";

my %Template1 :shared;
my %Template2 :shared;
while ($line = <INPUT>) {
    chop($line);
    ($cntx1, $cntx2) = split (" ", $line);
    
    if(!exists $Template1{$cntx1}){
        $Template1{$cntx1} = &share( {} );
    }
    if(!exists $Template2{$cntx2}){
        $Template2{$cntx2} = &share( {} );
    }
    
    $Template1{$cntx1}{$cntx2}++;
    $Template2{$cntx2}{$cntx1}++;
    #print STDERR "$Template{$cntx2}\n";
}



sub worker {
    $file = "temporal_ivan_".threads->tid();
    open ($fich, ">".$file) or die "O ficheiro temporal non pode ser creado: $!\n";
    $mutex->down();
    
    my ($job) = @_;
    for (@$job) {
        my $line = $_;
        chop($line);
        ($cntx, $pal, $freq, $ling) = split (" ", $line);
        $c1= $cntx . "\#" . $L1;
        $c2= $cntx . "\#" . $L2;
        
        if ( (defined $Template1{$c1}) && ($ling eq $L1) ) {
            $count++;
            foreach $translation  (keys %{ $Template1{$c1} }) {
                printf $fich "%s\;%s %s %d\n", $c1, $translation, $pal, $freq;
            }
        }
        elsif ( (defined $Template2{$c2}) && ($ling eq $L2) ) {
            foreach $translation  (keys %{ $Template2{$c2} }) {
                printf $fich "%s\;%s %s %d\n",  $translation, $c2,  $pal, $freq;
            }
        }
        
    }
    
    close($fich);
    
    $mutex->up();
}

my $q = Thread::Queue->new(); #::any

async { while (defined( my $job = $q->dequeue() )) { worker($job); } }
for 1..NUM_WORKERS;

my $done = 0;    
while (!$done) {
    my @lines;
    while (@lines < WORK_UNIT_SIZE) {
        my $line = <STDIN>;
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


print STDERR "foi gerado o ficheiro dos templates\n";
