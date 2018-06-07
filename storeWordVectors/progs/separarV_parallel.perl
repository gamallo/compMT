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

  #Verb
 if (
        #$cntx =~ /Dobj\_up/ || $cntx =~ /Iobj\&[^ ]*\_up/ || $cntx =~ /Subj\_up/ ||
      $cntx =~ /Dobj\_up/ || $cntx =~ /Iobj\&[^_]*\_up/ |  $cntx =~ /Subj\_up/ ||
        $cntx =~ /DobjV\_(up|down)/ || $cntx =~ /IobjV\&[^_]*\_(up|down)/ || $cntx =~ /SubjV\_(up|down)/ ||
        $cntx =~ /Vmod\_up/ || $cntx =~ /RmodV\_up/ || $cntx =~ /LmodV\_up/ || $cntx =~ /VmodV\_(up|down)/ ) {

          print  "$cntx $pal $f $ling\n";
  }
  }

  ##Adj
#  if ( $cntx =~ /Lmod\_up/ || $cntx =~ /Aprep\&[^ ]*\_down/ || $cntx =~ /Rmod\_up/ ||
#       $cntx =~ /Lmod\_up/ || $cntx =~ /AprepV\&[^ ]*\_down/ || $cntx =~ /Vmod\_up/) {
#      print  "$cntx $pal $f $ling\n";
#  }

   ##AdV                                                                                                                                              
#  if ( $cntx =~ /LmodA\_up/ || $cntx =~ /LmodV\_up/ || $cntx =~ /RmodV\_up/ ) {
#      print  "$cntx $pal $f $ling\n";
#  }

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

print STDERR "Done V.\n\n";
