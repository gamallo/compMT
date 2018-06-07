#!/usr/bin/perl 

use threads;
use Thread::Queue 3.01 qw( );

use constant NUM_WORKERS    => 4;
use constant WORK_UNIT_SIZE => 10000;

my %Dico :shared = {};

sub worker {
    my ($job) = @_;

    for (@$job) {
        $line = $_;
        chomp($line);
        ($expr1, $expr2) = split (" ", $line);
        
        if(!exists $Dico{$expr1}){
            my %sha :shared = {};
            $Dico{$expr1} = \%sha;
        }
        if(!exists $Dico{$expr1}{$expr2}){
            my $shar :shared = 0;
            $Dico{$expr1}{$expr2} = \$shar;
        }
        $Dico{$expr1}{$expr2}++;
    }
}

my $q = Thread::Queue->new();

async { while (defined( my $job = $q->dequeue() )) { worker($job); } }
for 1..NUM_WORKERS;

my $done = 0;    
while (!$done) {
    my @lines;
    while (@lines < WORK_UNIT_SIZE) {
        my $line = <>;
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


sub worker2 {
    my $job = $_;
    
    foreach $e2 (keys %{$Dico{$job}}) {
        print "$job $e2\n";
        
    }
}

my $q = Thread::Queue->new();

async { while (defined( my $job = $q->dequeue() )) { worker2($job); } }
for 1..NUM_WORKERS;

foreach $e1 (sort keys %Dico) {   
    $q->enqueue($e1);
}


$q->end();
$_->join for threads->list; 

