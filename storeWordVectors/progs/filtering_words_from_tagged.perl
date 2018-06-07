#!/usr/bin/perl

##entrada deppattern
##filtra palavras com threshold
#$file = shift(@ARGV);
#open (FILE, $file) or die "O ficheiro n�o pode ser aberto: $!\n";

$th=shift(@ARGV);

while ($line = <STDIN>) {
    chomp $line;
   
   ($token, $lemma, $tag) = split(' ', $line) ;
    $lemma = $token if ($tag =~ /^NP/ || $tag =~ /NNP/);
    $lemma =~ s/\_/\@/g;

    $found=0;
    if ($tag =~ /^N/) {
      $tag = "NOUN";
      $found++;
    }
    elsif ($tag =~ /^V/) {
	$tag = "VERB";
        $found++;
    } 
    elsif ($tag=~ /^AQ/ || $tag=~ /^JJ/) {
        $tag = "ADJ";
        $found++;
    }
    elsif ($tag=~ /^R/) {
        $tag = "ADV";
        $found++;
    }


    if ($found) {
     $word = $lemma . "_" . $tag ;
     $Words{$word}++ ;
    }

}

foreach $w (keys %Words) {
    print "$w\n" if ($Words{$w} >= $th);
}
