package Distances;
use Exporter;

our @ISA = qw( Exporter );

# these CAN be exported.
#our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( cosineBin diceBin cosine jaccard);

sub cosineBin {
    $input = shift(@_);
    my @tHead = split( "\n", $input );
    my @pares = split( "\n", shift(@_));    #arq
    my $res   = "";
    my %dic;
    my %Obj;

    $mycount=0;

    while ($line = shift(@tHead)) {
      chomp $line;
      my ($atributo, $objecto, $freq) = split (" ", $line);

      $dic{$objecto}{$atributo} = $freq;
      #$freqObj{$objecto} += $freq;
      # print STDERR "CREADO ". $objecto . "\n";
      $Obj{$objecto}++;
     # $freqAtr{$atributo} += $freq;
      $nrels++;


      $mycount++;

    }

    $mycount = 0;



    while ($line = shift(@pares)) {
      chomp $line;

      my ($obj1, $obj2) = split (" ", $line);


      $baseline = 0;
      $cosineBin = 0;
      foreach $atr (keys %{ $dic{$obj1} }) {
          #   print STDERR "ATR: #$atr# - #$obj1# -  #$obj2#\n";
          ##buscar atributos comuns
        if (defined $dic{$obj2}{$atr}) {
              $baseline++ ;
       }


      }

      # print STDERR "BUSCANDO ". $obj1 . " y " . $obj2 . "\n";
      if ( (defined $Obj{$obj1}) && (defined $Obj{$obj2}) )  {
          $cosineBin = $baseline / sqrt ($Obj{$obj1} * $Obj{$obj2} )   ;
      }

      if($cosineBin){
          $res .= sprintf("%s %s %f\n", $obj1, $obj2, $cosineBin);
      }
      else {
          $res .= sprintf("%s %s 0\n", $obj1, $obj2);
      }
    }

    return $res;
}

sub jaccard {
    my $input = shift(@_);
    my @tHead = split( "\n", $input );
    my @pares = split( "\n", shift(@_) );    #arq
    my $res   = "";

    my $CARD = shift(@_);                    # recomendado: 1

    my %dic;
    my %freqObj;
    my %Obj;


    my $mycount=0;

    while ($line = shift(@tHead)) {
      chomp $line;
      my ($atributo, $objecto, $freq) = split (" ", $line);

#      print STDERR $atributo . " -- " . $objecto . " -- " . $freq . "\n";
      $dic{$objecto}{$atributo} = $freq;
      $freqObj{$objecto} += $freq;
      $Obj{$objecto}++;
     # $freqAtr{$atributo} += $freq;
      $nrels++;

      #print STDERR "#$objecto# - #$atributo# - #$dic{$objecto}{$atributo}#\n";
      $mycount++;
    }

    $mycount = 0;

    while ($line = shift(@pares)) {
      chomp $line;
      ($obj1, $obj2) = split (" ", $line);

      #print STDERR "#$obj1# - #$obj2#\n";
      $mycount++;

      $baseline = 0;
      $diceBin = 0;
      $diceMin = 0;
      $jaccard = 0;
      $cosineBin = 0;
      $cosine = 0;
      $city = 0;
      $euclidean = 0;
      $js = 0;
      $lin = 0;
      $jaccardMax = 0;


     # $rels = "";
      $min = 0;
      $max = 0;
      $sum_intersection = 0;
      $intersection = 0;
      $o1 = 0;
      $o2 = 0;
      $d1 = 0;
      $d2 = 0;

     #print STDERR "#$obj1# - #$obj2#\n";
      foreach $atr (keys %{ $dic{$obj1} }) {
       #print STDERR "#$obj1# - #$obj2#\n";
        $assoc1 = 0;
        $assoc2 = 0;
        ##buscar atributos comuns
        if (defined $dic{$obj2}{$atr}) {
             $baseline++;
      #       $rels = $rels . "|" . $atr ;
             $assoc1 = $dic{$obj1}{$atr} ;
             $assoc2 = $dic{$obj2}{$atr} ;



             $min += Min ($assoc1, $assoc2) ;
             $max += Max ($assoc1, $assoc2) ;


             $city += abs ($assoc1 -  $assoc2 ) ;
             $euclidean += ($assoc1 -  $assoc2 ) **2 ;

             $prob1 = $assoc1 / $freqObj{$obj1};
             $prob2 = $assoc2 / $freqObj{$obj2};
             $prob1_2  = ($prob1 + $prob2) / 2;

             if ($prob1 > 0 && $prob1_2 > 0) {
               $d1 += $prob1 * (log($prob1 / $prob1_2)/log(2)) ;
    	 }
    	 if ($prob2 > 0 && $prob1_2 > 0) {
               $d2 += $prob2 * (log($prob2 / $prob1_2)/ log(2)) ;
             }

             $intersection += $assoc1 *  $assoc2 ;
             $sum_intersection += $assoc1 + $assoc2 ;
             $o1 += $assoc1 **2 ;
             $o2 += $assoc2 **2 ;


        }

        elsif (defined $dic{$obj1}{$atr}) {
          $max += $dic{$obj1}{$atr} ;
          $city += $dic{$obj1}{$atr} ;
          $euclidean += $dic{$obj1}{$atr}**2 ;
          $o1 += $dic{$obj1}{$atr} **2 ;


        }

      }

      foreach $atr2 (keys %{ $dic{$obj2} }) {

         if (!defined $dic{$obj1}{$atr2} ) {
             $max += $dic{$obj2}{$atr2} ;
             $city += $dic{$obj2}{$atr2} ;
             $euclidean += $dic{$obj2}{$atr2}**2 ;
             $o2 +=  $dic{$obj2}{$atr2} **2 ;

         }
      }


       ##computar formulas finais:

      ##diceBin diceMin:



       ##jaccardMax:
       if ($max > 0) {
         $jaccardMax = $min / $max ;
       }

      ##diceBin, cosineBin, $jaccard
      if ( (defined $Obj{$obj1}) && (defined $Obj{$obj2}) )  {
        $diceBin = (2*$baseline) / ($Obj{$obj1} + $Obj{$obj2}) ;
        $cosineBin = $baseline / sqrt ($Obj{$obj1} * $Obj{$obj2} ) ;
        $jaccard = $baseline / ($Obj{$obj1} + $Obj{$obj2} - $baseline )
      }

      ##diceMin, cosine, lin:
      if ( (defined $freqObj{$obj1}) && (defined $freqObj{$obj2}) )  {
        # print STDERR "#$obj1# - #$obj2# #$min#\n";
        $diceMin = (2*$min) / ($freqObj{$obj1} + $freqObj{$obj2}) ;
        $lin = $sum_intersection / ($freqObj{$obj1} + $freqObj{$obj2} ) ;
      }

      ##cosine
      if ( ($o1 > 0) && ($o2 > 0) )  {
        $cosine = $intersection / (sqrt ($o1 * $o2) ) ;
      }

      ##euclidean:
      $euclidean = sqrt ($euclidean);

      ##js
      $js = ( $d1 + $d2 ) / 2 ;

      if  ($baseline >= $CARD)  {
       #  printf "%s %s %d %f %f %f %f %f %f %f %f %f %f\n", $obj1, $obj2, $baseline, $diceBin, $diceMin, $jaccard, $cosineBin, $cosine, $city, $euclidean, $js, $lin, $jaccardMax;
           $res .= sprintf("%s %s %f\n", $obj1, $obj2, $jaccard);
      }
      else {
          $res .= sprintf("%s %s 0\n", $obj1, $obj2);
      }
    }

    return $res;
}

sub cosine {
  my $input = shift(@_);
  my @tHead = split( "\n", $input );
  my @pares = split( "\n", shift(@_) );    #arq
  my $res   = "";

  my $CARD = shift(@_);                    # recomendado: 1

  my %dic;
  my %freqObj;
  my %Obj;


  my $mycount=0;

  while ($line = shift(@tHead)) {
    chomp $line;
    my ($atributo, $objecto, $freq) = split (" ", $line);

  #      print STDERR $atributo . " -- " . $objecto . " -- " . $freq . "\n";
    $dic{$objecto}{$atributo} = $freq;
    $freqObj{$objecto} += $freq;
    $Obj{$objecto}++;
   # $freqAtr{$atributo} += $freq;
    $nrels++;

    #print STDERR "#$objecto# - #$atributo# - #$dic{$objecto}{$atributo}#\n";
    $mycount++;
  }

  $mycount = 0;

    while ($line = shift(@pares)) {
      chomp $line;
      ($obj1, $obj2) = split (" ", $line);


      #print STDERR "#$obj1# - #$obj2#\n";
      $mycount++;
      if ($mycount % 1000 == 0) {

      }

      $baseline = 0;
      $diceBin = 0;
      $diceMin = 0;
      $jaccard = 0;
      $cosineBin = 0;
      $cosine = 0;
      $city = 0;
      $euclidean = 0;
      $js = 0;
      $lin = 0;
      $jaccardMax = 0;


     # $rels = "";
      $min = 0;
      $max = 0;
      $sum_intersection = 0;
      $intersection = 0;
      $o1 = 0;
      $o2 = 0;
      $d1 = 0;
      $d2 = 0;

     #print STDERR "#$obj1# - #$obj2#\n";
      foreach $atr (keys %{ $dic{$obj1} }) {
       #print STDERR "#$obj1# - #$obj2#\n";
        $assoc1 = 0;
        $assoc2 = 0;
        ##buscar atributos comuns
        if (defined $dic{$obj2}{$atr}) {
             $baseline++ ;
      #       $rels = $rels . "|" . $atr ;
             $assoc1 = $dic{$obj1}{$atr} ;
             $assoc2 = $dic{$obj2}{$atr} ;



             $min += Min ($assoc1, $assoc2) ;
             $max += Max ($assoc1, $assoc2) ;


             $city += abs ($assoc1 -  $assoc2 ) ;
             $euclidean += ($assoc1 -  $assoc2 ) **2 ;

             $prob1 = $assoc1 / $freqObj{$obj1};
             $prob2 = $assoc2 / $freqObj{$obj2};
             $prob1_2  = ($prob1 + $prob2) / 2;

             if ($prob1 > 0 && $prob1_2 > 0) {
               $d1 += $prob1 * (log($prob1 / $prob1_2)/log(2)) ;
    	 }
    	 if ($prob2 > 0 && $prob1_2 > 0) {
               $d2 += $prob2 * (log($prob2 / $prob1_2)/ log(2)) ;
             }

             $intersection += $assoc1 *  $assoc2 ;
             $sum_intersection += $assoc1 + $assoc2 ;
             $o1 += $assoc1 **2 ;
             $o2 += $assoc2 **2 ;


        }

        elsif (defined $dic{$obj1}{$atr}) {
          $max += $dic{$obj1}{$atr} ;
          $city += $dic{$obj1}{$atr} ;
          $euclidean += $dic{$obj1}{$atr}**2 ;
          $o1 += $dic{$obj1}{$atr} **2 ;


        }

      }

      foreach $atr2 (keys %{ $dic{$obj2} }) {

         if (!defined $dic{$obj1}{$atr2} ) {
             $max += $dic{$obj2}{$atr2} ;
             $city += $dic{$obj2}{$atr2} ;
             $euclidean += $dic{$obj2}{$atr2}**2 ;
             $o2 +=  $dic{$obj2}{$atr2} **2 ;

         }
      }


       ##computar formulas finais:

      ##diceBin diceMin:



       ##jaccardMax:
       if ($max > 0) {
         $jaccardMax = $min / $max ;
       }

      ##diceBin, cosineBin, $jaccard
      if ( (defined $Obj{$obj1}) && (defined $Obj{$obj2}) )  {
        $diceBin = (2*$baseline) / ($Obj{$obj1} + $Obj{$obj2}) ;
        $cosineBin = $baseline / sqrt ($Obj{$obj1} * $Obj{$obj2} ) ;
        $jaccard = $baseline / ($Obj{$obj1} + $Obj{$obj2} - $baseline )
      }

      ##diceMin, cosine, lin:
      if ( (defined $freqObj{$obj1}) && (defined $freqObj{$obj2}) )  {
        # print STDERR "#$obj1# - #$obj2# #$min#\n";
        $diceMin = (2*$min) / ($freqObj{$obj1} + $freqObj{$obj2}) ;
        $lin = $sum_intersection / ($freqObj{$obj1} + $freqObj{$obj2} ) ;
      }

      ##cosine
      if ( ($o1 > 0) && ($o2 > 0) )  {
        $cosine = $intersection / (sqrt ($o1 * $o2) ) ;
      }

      ##euclidean:
      $euclidean = sqrt ($euclidean);

      ##js
      $js = ( $d1 + $d2 ) / 2 ;

      if  ($baseline >= $CARD)  {
       #  printf "%s %s %d %f %f %f %f %f %f %f %f %f %f\n", $obj1, $obj2, $baseline, $diceBin, $diceMin, $jaccard, $cosineBin, $cosine, $city, $euclidean, $js, $lin, $jaccardMax;
           $res .= sprintf("%s %s %f\n", $obj1, $obj2, $cosine);
      }
      else {
          $res .= sprintf("%s %s 0\n", $obj1, $obj2);
      }

    }
    return $res;
}

sub diceBin {
  my $input = shift(@_);
  my @tHead = split( "\n", $input );
  my @pares = split( "\n", shift(@_) );    #arq
  my $res   = "";

  my $CARD = shift(@_);                    # recomendado: 1

  my %dic;
  my %freqObj;
  my %Obj;


  my $mycount=0;

  while ($line = shift(@tHead)) {
    chomp $line;
    my ($atributo, $objecto, $freq) = split (" ", $line);

  #      print STDERR $atributo . " -- " . $objecto . " -- " . $freq . "\n";
    $dic{$objecto}{$atributo} = $freq;
    $freqObj{$objecto} += $freq;
    $Obj{$objecto}++;
   # $freqAtr{$atributo} += $freq;
    $nrels++;

    #print STDERR "#$objecto# - #$atributo# - #$dic{$objecto}{$atributo}#\n";
    $mycount++;
  }

  $mycount = 0;

  while ($line = shift(@pares)) {
    chomp $line;
    ($obj1, $obj2) = split (" ", $line);



    #print STDERR "#$obj1# - #$obj2#\n";
    $mycount++;

    $baseline = 0;
    $diceBin = 0;
    $diceMin = 0;
    $jaccard = 0;
    $cosineBin = 0;
    $cosine = 0;
    $city = 0;
    $euclidean = 0;
    $js = 0;
    $lin = 0;
    $jaccardMax = 0;


   # $rels = "";
    $min = 0;
    $max = 0;
    $sum_intersection = 0;
    $intersection = 0;
    $o1 = 0;
    $o2 = 0;
    $d1 = 0;
    $d2 = 0;

   #print STDERR "#$obj1# - #$obj2#\n";
    foreach $atr (keys %{ $dic{$obj1} }) {
     #print STDERR "#$obj1# - #$obj2#\n";
      $assoc1 = 0;
      $assoc2 = 0;
      ##buscar atributos comuns
      if (defined $dic{$obj2}{$atr}) {
           $baseline++ ;
    #       $rels = $rels . "|" . $atr ;
           $assoc1 = $dic{$obj1}{$atr} ;
           $assoc2 = $dic{$obj2}{$atr} ;



           $min += Min ($assoc1, $assoc2) ;
           $max += Max ($assoc1, $assoc2) ;


           $city += abs ($assoc1 -  $assoc2 ) ;
           $euclidean += ($assoc1 -  $assoc2 ) **2 ;

           $prob1 = $assoc1 / $freqObj{$obj1};
           $prob2 = $assoc2 / $freqObj{$obj2};
           $prob1_2  = ($prob1 + $prob2) / 2;

           if ($prob1 > 0 && $prob1_2 > 0) {
             $d1 += $prob1 * (log($prob1 / $prob1_2)/log(2)) ;
  	 }
  	 if ($prob2 > 0 && $prob1_2 > 0) {
             $d2 += $prob2 * (log($prob2 / $prob1_2)/ log(2)) ;
           }

           $intersection += $assoc1 *  $assoc2 ;
           $sum_intersection += $assoc1 + $assoc2 ;
           $o1 += $assoc1 **2 ;
           $o2 += $assoc2 **2 ;


      }

      elsif (defined $dic{$obj1}{$atr}) {
        $max += $dic{$obj1}{$atr} ;
        $city += $dic{$obj1}{$atr} ;
        $euclidean += $dic{$obj1}{$atr}**2 ;
        $o1 += $dic{$obj1}{$atr} **2 ;


      }

    }

    foreach $atr2 (keys %{ $dic{$obj2} }) {

       if (!defined $dic{$obj1}{$atr2} ) {
           $max += $dic{$obj2}{$atr2} ;
           $city += $dic{$obj2}{$atr2} ;
           $euclidean += $dic{$obj2}{$atr2}**2 ;
           $o2 +=  $dic{$obj2}{$atr2} **2 ;

       }
    }


     ##computar formulas finais:

    ##diceBin diceMin:



     ##jaccardMax:
     if ($max > 0) {
       $jaccardMax = $min / $max ;
     }

    ##diceBin, cosineBin, $jaccard
    if ( (defined $Obj{$obj1}) && (defined $Obj{$obj2}) )  {
      $diceBin = (2*$baseline) / ($Obj{$obj1} + $Obj{$obj2}) ;
      $cosineBin = $baseline / sqrt ($Obj{$obj1} * $Obj{$obj2} ) ;
      $jaccard = $baseline / ($Obj{$obj1} + $Obj{$obj2} - $baseline )
    }

    ##diceMin, cosine, lin:
    if ( (defined $freqObj{$obj1}) && (defined $freqObj{$obj2}) )  {
      # print STDERR "#$obj1# - #$obj2# #$min#\n";
      $diceMin = (2*$min) / ($freqObj{$obj1} + $freqObj{$obj2}) ;
      $lin = $sum_intersection / ($freqObj{$obj1} + $freqObj{$obj2} ) ;
    }

    ##cosine
    if ( ($o1 > 0) && ($o2 > 0) )  {
      $cosine = $intersection / (sqrt ($o1 * $o2) ) ;
    }

    ##euclidean:
    $euclidean = sqrt ($euclidean);

    ##js
    $js = ( $d1 + $d2 ) / 2 ;

    if  ($baseline >= $CARD)  {
     #  printf "%s %s %d %f %f %f %f %f %f %f %f %f %f\n", $obj1, $obj2, $baseline, $diceBin, $diceMin, $jaccard, $cosineBin, $cosine, $city, $euclidean, $js, $lin, $jaccardMax;
         $res .= sprintf("%s %s %f\n", $obj1, $obj2, $diceBin);
    }
    else {
        $res .= sprintf("%s %s 0\n", $obj1, $obj2);
    }

  }

    return $res;
}

sub Min {
    local ($x) = $_[0];
    local ($y) = $_[1];

    if ( $x <= $y ) {
        return $x;
    }
    return $y;
}

sub Max {
    local ($x) = $_[0];
    local ($y) = $_[1];

    if ( $x >= $y ) {
        return $x;
    }
    return $y;
}

1;
