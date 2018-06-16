#!/usr/bin/perl -w

#1;4205;0c#Toma como entrada a saída do FreeLing e devolve um texto etiquetado com algumas modificaçoes: verbos compostos, elimina determinantes e pronomes, etc.

$file = shift(@ARGV);
open (FILE, $file) or die "O ficheiro n�o pode ser aberto: $!\n";


while (my $line = <FILE>) {
   chomp($line);
   my ($mw, $cat) = split ("_", $line);
   $mw =~ s/@/_/g;
   (@mw) = split ("_", $mw);
   $First{$mw[0]}++;
   $cat = "N" if ($cat && $cat eq "NOUN");
   $cat = "V" if ($cat && $cat eq "VERB");
   $MW{$mw} = $cat;
   
#   print STDERR "#$mw# - #$cat#\n";
}


$separador = "Fp" ;
$/ = $separador;

$window=3;
while (my $sent = <STDIN>) {
  my $Found=0;
  my @sent = split ('\n', $sent);
  #print STDERR "#$sent#\n";
   %Found=();
   $Found=0;
   for ($i=0;$i<=$#sent;$i++) {
    if (!$sent[$i]){next}
    ($pal, $lema, $tag) = split(" ", $sent[$i]);
    if (!$lema) {next}

    #$Pal[$i] = $pal;
    $init = $i + 1;
    $last = $i + $window;
    $target = $lema;
    $pal_i="";
    $tag_i="";
    $target_se = "";
    if ($First{$lema}) {

	for ($j=$init;$j<=$last;$j++) {
	    ($pal_i, $lema_i, $tag_i) = split(" ", $sent[$j]) if ($sent[$j]);
           
            $target = $target . "_" . $lema_i  ;
	    $target_se = $target_se . "_" . $lema_i if($target_se) ;
	  
	    if ($MW{$target}) {
		$Found{$target} = $j;
		$Found=1;
	#	print STDERR "---> #$target# - #$i#-#$j#\n";
	    }
	    
	}
   
        if ($Found) {
          foreach $mw  (sort {$Found{$b} <=>
		        $Found{$a} }
		  keys %Found ) {
	    if ($i >  $Found{$mw}){last}
            $Lema[$i] = $mw;
            $Pal[$i] = $mw;
	    $Tag[$i] = "NN" if ($MW{$mw} eq "N");
            $Tag[$i] = "VBD" if ($MW{$mw} eq "V");

            #$i=$i+$j;
          #  print STDERR "Found---> #$mw# - #$i#-#$Found{$mw}#\n";
            $i=$Found{$mw};
            last;
          }
	  next
	}
    }

     $Pal[$i] = $pal;
     $Lema[$i] = $lema;
     $Tag[$i] = $tag;
    # print STDERR "-$Lema[$i] -- #$i#!!\n";


   
  }


  if ($Found) {
   for ($i=0;$i<=$#Pal;$i++) {
       print "$Pal[$i] $Lema[$i] $Tag[$i]\n" if ($Pal[$i] && $Tag[$i]);
   }
   print "\n";
 }
  undef @Pal;
  undef @Lema;
  undef @Tag;
  undef %Found;
}
