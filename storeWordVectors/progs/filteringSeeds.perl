#!/usr/bin/perl

# LE O FICHEIRO FREQ E DEIXA AQUELES CONTXS QUE TÊM UMA FREQUENCIA ENTRE DOUS THRESHOLDS E ELIMINA PALAVRAS POUCO FREQUENTES,



#lê um ficheiro com todos os freqs (cntx pal freq) (pipe)



while ($line = <STDIN>) {
      chomp($line);
      ($expr1, $expr2) = split (" ", $line);
      
      $Dico{$expr1}{$expr2}++

}

foreach $e1 (sort keys %Dico) {
    foreach $e2 (keys %{$Dico{$e1}}) {
        print "$e1 $e2\n";
    }

}
