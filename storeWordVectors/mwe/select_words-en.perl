#!/usr/bin/perl -w

##Toma como entrada a saída do FreeLing e devolve um texto etiquetado com algumas modificaçoes: verbos compostos, elimina determinantes e pronomes, etc.

$file = shift(@ARGV);
open (FILE, $file) or die "O ficheiro n�o pode ser aberto: $!\n";


while (my $line = <FILE>) {
   chomp($line);
   my ($mw, $cat) = split ("_", $line);
   $mw =~ s/@/_/g;
   $cat = "N" if ($cat && $cat eq "NOUN");
   $cat = "V" if ($cat && $cat eq "VERB");
   $MW{$mw} = $cat;
   print STDERR "#$mw# - #$cat#\n";
}


$separador = "Fp\n" ;
$/ = $separador;


while (my $sent = <STDIN>) {
  my $Found=0;
  my @sent = split ('\n', $sent);
  #print STDERR "#$sent#\n";
   for ($i=0;$i<=$#sent;$i++) {
    if (!$sent[$i]){next}
    ($pal, $lema, $tag) = split(" ", $sent[$i]);
    
     $Pal[$i] = $pal;
     $Lema[$i] = $lema;
     $Tag[$i] = $tag;
     #print STDERR "$i\r";
   }
  

   foreach my $mw (keys %MW) {
     my @mw = split ("_", $mw);
     my $n = $#mw;
     for ($i=0;$i<=$#Pal;$i++) {

      $match=0;
      $k=$i;
      for ($j=0;$j<=$n;$j++) {
        #print STDERR "#$mw[$j]#  #$j#-- #$Pal[$k]# #$k#\n" if ($Pal[$k] eq "point") ;
        if (!$mw[$j] || !$Pal[$k]){next}
        if ($mw[$j] ne $Pal[$k]) {
          last
	}
	elsif ($mw[$j] eq $Pal[$k]) {
	    $match++;
             print STDERR "$j $k #$mw[$j]# :: #$Pal[$k]# = #$match# $n\n" if ($Pal[$k] eq "point");
	}
        $k=$k+1;

       
     }
    ###hai que construir o vector inteiro e despois percorrer com os mw.
     #print STDERR "#$match# --> #$n#\n";
     if ($match == $n+1) {
        $Pal[$i] = $mw;
        $Lema[$i] = $mw;
        $Tag[$i] = "NN" if ($MW{$mw} eq "N");
#        $Tag[$i] = "VM0000" if ($MW{$mw} eq "V"); ##spanish
        $Tag[$i] = "VBD" if ($MW{$mw} eq "V");
        $k= $i+1;
        for ($j=$k;$j<$k+$n;$j++) {
            #print STDERR "##$Pal[$j]##\n";
	    #delete $Pal[$j];
  	    #delete $Lema[$j];
	    #delete $Tag[$j];
            $Pal[$j] = "<nao>";
  	    
	}
	$i = $i+$n;
       
        $Found=1;
        print STDERR "MW: #$mw# #$i#\n";
    }
   }
  
   
   } 
   if ($Found && @Pal) {
    for ($i=0;$i<=$#Pal;$i++) {
	if (!$Pal[$i] || $Pal[$i] eq "<nao>") {next}
       print "$Pal[$i] $Lema[$i] $Tag[$i]\n";
    }
  }
   undef @Pal;
   undef @Lema;
   undef @Tag;

}
