#!/usr/bin/perl

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
$stopwords = "ought|must|should";

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


$countMIN=0;
$countMAX=0;
$count=0;
foreach $t (sort keys %Templates) {
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
    if ($Diff <= $th1) {
        $countMIN++;
        # print STDERR "#MIN: $t#\n";

    }
    elsif ($Diff >= $th2) {
        $countMAX++;
        print STDERR "#MAX: $t#\n";
    }
    else {
        foreach $w (keys %Freq) {
            if ( ($Freq{$w} ne "") && ($Words{$w} >= $th3) ) {
                print "$t $w $Freq{$w}\n";
                $Found{$t}++;
            }
        }
        if (defined $Found{$t}) {
            $count++;
        }
    }


}


print STDERR "MIN cntx removidos: ##$countMIN##\n";
print STDERR "MAX cntx removidos: ##$countMAX##\n";
print STDERR "numero total de pals: ##$numPals##\n";
print STDERR "numero de contextos: ##$count##\n";
print STDERR "foi gerado o ficheiro filtrado de contextos-pal-freq\n";
