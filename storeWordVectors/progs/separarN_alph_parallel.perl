#!/usr/bin/perl 

#
#  Separa o ficheiro de atributos em 3 conjuntos,
#  onde cada conjunto uma categoria: Adjs Nomes e Verbos
#
#  Modifs:
#     - 19fev2003 - modif a relação adj (down<-->up)
#

use threads;
use Thread::Queue 3.01 qw( );

use constant NUM_WORKERS    => 4;
use constant WORK_UNIT_SIZE => 100000;

$PART=shift(@ARGV);

$pref="./tmp/__separadoN_";

sub worker {
    $letter = threads->tid();
    open $file, ">$pref$letter" or die "nao consegui abrir un ficheiro temporal!";
    
    my ($job) = @_;
    for (@$job) {
        my $line = $_;
    chomp $line;
    ($cntx, $pal, $f) = split(" ", $line);
    
    if ( $cntx =~ /Dobj\_down/ || $cntx =~ /Iobj\&[^_]*\_down/ || $cntx =~ /Subj\_down/ ||
        $cntx =~ /Aprep\&[^_]*\_down/ || $cntx =~ /[LR]mod\_up/ || $cntx =~ /Cprep\&[^_]*\_(up|down)/ ||
        $cntx =~ /modN\_(up|down)/ ) {  
        
        ($letter) = $pal =~ /^([\w])/;
        print $file "$cntx $pal $f\n";
            
    }
        
    }

    close $file;
        
}


my $q = Thread::Queue->new(); #::any

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





print STDERR "Done N.\n\n";
