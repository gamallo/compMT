#!/usr/bin/perl 

use threads;
use Thread::Queue 3.01 qw( );

use constant NUM_WORKERS    => 8;
use constant WORK_UNIT_SIZE => 100000;

$th=shift(@ARGV);

my %Words :shared = ();

sub worker {
    my ($job) = @_;
    lock %Words;
    for (@$job) {
        $line = $_;
        chomp $line;
        ($rel, $head, $dep) = split('\;', $line) if ($line =~ /^\(/);

        ($word) = $head =~ /([^_]+\_[^_]+)/;
        #print  "word: #$word#\n";
        $Words{$word}++ if ($word && $word !~ /_$/ && $word !~ / /);
        ($word) = $dep =~ /([^_]+\_[^_]+)/;
        #print STDERR "word: #$word#\n";
        $Words{$word}++ if ($word && $word !~ /_$/ && $word !~ / /);
    }

    @keys = keys %Words;
    $size = @keys;    
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

            
foreach $w (keys %Words) {
    print "$w\n" if ($Words{$w} >= $th);
}

