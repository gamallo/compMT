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


sub worker { #le cada linha do arquivo
my ($job) = @_;
    for (@$job) {
        my $line = $_;
   chomp $line;
  ($cntx, $pal, $f, $ling) = split(" ", $line);
 
  #print STDERR "$cntx -- $pal --- $f \n";


  ##Adj
  if ( $cntx =~ /Lmod\_down/ || $cntx =~ /Aprep\&[^_]*\_up/ || $cntx =~ /Rmod\_down/ ||
       $cntx =~ /AprepV\&[^_]*\_up/ || $cntx =~ /Vmod\_down/) {
      print  "$cntx $pal $f $ling\n";
  }

   ##AdV                                                                                                                                              
#  if ( $cntx =~ /LmodA\_up/ || $cntx =~ /LmodV\_up/ || $cntx =~ /RmodV\_up/ ) {
#      print  "$cntx $pal $f $ling\n";
#  }
}

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

print STDERR "Done A.\n\n";
