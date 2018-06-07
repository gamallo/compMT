#!/usr/bin/perl

use threads;
use Thread::Queue 3.01 qw( );

use constant NUM_WORKERS    => 4;
use constant NUM_CORES => 4;
# LE O FICHEIRO FREQ E DEIXA AQUELES CONTXS QUE TÊM UMA FREQUENCIA ENTRE DOUS THRESHOLDS E ELIMINA PALAVRAS POUCO FREQUENTES,



#lê um ficheiro com todos os freqs (cntx pal freq) (pipe)


##threshold minimo: 2  (num. minimo de palavras)
$th1 = shift(@ARGV);
#threshold maximo 2000
$th2 = shift(@ARGV);
#theshold de palavras: 5
$th3 = shift(@ARGV);

$file = shift(@ARGV);
open (FILE, $file) or die "O ficheiro n�o pode ser aberto: $!\n";

while ($t = <FILE>) {
    chomp $t;
    $Templates{$t}++;
    
}


##formas stopwords
$stopwords = "be|have|take|get|must|should";

$freq="";
$numPals=0;
while ($line = <STDIN>) {
    chomp($line);
    ($template, $word, $freq) = split (" ", $line);
    if (!$Templates{$template}) {
        next;
    }
    
    if ($word =~ /^($stopwords)$/) {next}
    
    $Templates{$template} .= "|" . $word . "=" .  $freq;
    #if (!defined $Words{$word}) {
    #	  $numPals++;
    #      }
    $Words{$word}++;
    #  $Dico{$template}{$word} = $freq;
    
    
    #print STDERR "$Template{$cntx2}\n";
}

my @parameters = sort keys %Templates;
my $numWorkers = length(@parameters) / NUM_CORES;

sub worker {
    my ($job) = @_;
    
    $file = "temporal_ivan_".threads->tid();
    open ($fich, ">".$file) or die "O ficheiro temporal non pode ser creado: $!\n";
    
    for $t (@$job) {
        undef %Freq;
        $Diff=0; 
        @words = split ('\|', $Templates{$t});
        #$media = ($#words / $numPals);
        foreach $pair (@words) {
            ($w, $freq) = split ("=", $pair);
            #print STDERR "#$t# -- #$w#\n";
            $Diff++ ;
            $Freq{$w} = $freq;
        }
        if (!($Diff <= $th1) and  !($Diff >= $th2)) {
            foreach $w (keys %Freq) {
                if ( ($Freq{$w} ne "") && ($Words{$w} >= $th3) ) {
                    print $fich "$t $w $Freq{$w}\n";
                    $Found{$t}++;
                }
            }  
        }
    }
    
    close($fich);
    
}

my $q = Thread::Queue->new(); #::any

async { while (defined( my $job = $q->dequeue() )) { worker($job); } }
    for 1..NUM_WORKERS;

my @buffer;
for (@parameters){
    my $current = $_;
    
    push @buffer, $current;
    
    if(length(@buffer) >= WORK_UNIT_SIZE){
        $q->enqueue(\@buffer) if @buffer;    
        @buffer = ();
    }
}
    
    

$q->end();
$_->join for threads->list; 



print STDERR "foi gerado o ficheiro filtrado de contextos-pal-freq\n";
