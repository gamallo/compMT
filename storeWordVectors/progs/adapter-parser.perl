#!/usr/bin/perl

use feature 'say';

use Parallel::ForkManager; 

##Entrada: saida do Freeling
##Saida: entrada do parsingCascataByRegularExpressions.perl


## Lexemas gramaticais especiais:
my $AUX="(have|avoir|ter|haber|haver)";
my $COP="(be|�tre|ser)";




my $Pos=0;
my $FoundFinal=0;

my $max_procs = 4; 
my $pm = new Parallel::ForkManager($max_procs);   

my %ret_data;

$pm->run_on_finish( sub { 
    my ($pid, $exit, $ident, $signal, $core, $dataref) = @_; 
    $ret_data{$pid} = $dataref;
});

my $num_lines_to_collect = 10;

my @lines_to_process;         # collect lines for each fork

while (my $input = <STDIN>)
{
    chomp($input);
    push @lines_to_process, $input;
    next if $. % $num_lines_to_collect != 0;

    $pm->start and next;
    print("aa");
    my $ret = run_job( @lines_to_process );
    $pm->finish(0);

    @lines_to_process = ();   # empty it for the next round
}
$pm->wait_all_children;


sub run_job { 
    for(@_){
          print(@_);
   chop($_);

  if ($_ eq "" && $FoundFinal) {
      next
   }
   ##se hai um final de linha sem ponto final. So tem sentido com --flush
   elsif ($_ eq "" && !$FoundFinal) {
      # $Pos++;
       $pipe = "\.\tlemma:\.|tag:SENT|pos:$Pos|token:\.|\n";
       $FoundFinal=1;
       $Pos=0;
   }
 
   else {
     #troca do simbolo de composicao tipico de Freeling
     s/\_/\@/g ;
     
     ($token, $lemma, $tag) = split(" ", $_);

    ## reiniciar valor de FoundFinal
     if ($Pos==0) {
        $FoundFinal=0;
     }
   ##correc�oes ad hoc de problemas de etiqueta�ao:

 
   if ( ($lemma =~ /^pol[oa](s?)$/) && ($tag =~ /^SP/) ) {
           $lemma = "por"
   }


    #se temos um NP (nome proprio), colocar a forma no lema (para conservar a maiuscula)
     #se temos um poss�vel nome pr�prio (desconhecido ou composto), colocar a forma no lemma (para conservar a maiuscula)
   if ( ($token =~ /\&/) || ($tag =~ /^NP/) ) {
         $lemma = $token;
   }
  

 ##tag conversion:
 #mudar tags:
  # if ($tag =~ /^VIRG/) {
   #   $tag = "COMMA"
  # }

   ##pronomes:
   
   if ($tag =~ /^PP$/) {
      $Exp{"lemma"} = $lemma;
      $Exp{"token"} = $token;
      $Exp{"tag"} =  "PRO";
      $Exp{"type"} = "P";
      $Exp{"person"} = 0;
      $Exp{"gender"} = 0;
      $Exp{"number"} = 0;
      $Exp{"case"} = 0;    
      $Exp{"possessor"} = 0;    
      $Exp{"politeness"} = 0;

   } 
   elsif ($tag =~ /^W/) {
      $Exp{"lemma"} = $lemma;
      $Exp{"token"} = $token;
      $Exp{"tag"} =  "PRO";
      $Exp{"type"} = "W";
      $Exp{"person"} = 3;
      $Exp{"gender"} = 0;
      $Exp{"number"} = 0;
      $Exp{"case"} = 0;    
      $Exp{"possessor"} = 0;    
      $Exp{"politeness"} = 0;

   } 
      
     ##conjunctions:
    elsif ($tag =~ /^CC/) {
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "CONJ";
       $Exp{"type"} =  "C";      
    }

    elsif ( $lemma =~ /^that$/ && $tag =~ /^IN/ ) {
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "CONJ";
       $Exp{"type"} = "S";
     }      
  
    ##interjections:
    elsif ($tag =~ /^UH/) {
       (@tmp) = split ("", $tag);
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "I";
       $Exp{"type"} = 0;
      
    }

   ##numbers
   elsif ($tag =~  /^CD/) {
      # $lemma = "\@card\@";
       (@tmp) = split ("", $tag);
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "CARD";
       $Exp{"number"} = "P";
       $Exp{"person"} = 0;         
       $Exp{"gender"} = 0;         
       
   }


    elsif ($tag =~ /^JJ/) {
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "ADJ";
       $Exp{"type"} = 0;
       
       if ($tag =~ /R$/) {
          $Exp{"degree"} = "A";
       }
       elsif ($tag =~ /S$/) {
          $Exp{"degree"} = "S";
       }
       else {
          $Exp{"degree"} = 0;  
       }
       $Exp{"gender"} = 0;
       $Exp{"number"} = 0;
       $Exp{"function"} = 0;
   }


   elsif ($tag =~ /^RB/) {
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "ADV";
       if ($tag =~ /R$/) {
          $Exp{"degree"} = "A";
       }
       elsif ($tag =~ /S$/) {
          $Exp{"degree"} = "S";
       }
       else {
          $Exp{"degree"} = 0;  
       }
     
   }


   elsif ($tag =~ /(^IN$|^TO$)/) {
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "PRP";
       $Exp{"type"} = 0;
      
   }


   elsif ($tag =~ /^N/) {
       (@tmp) = split ("", $tag);
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "NOUN";
       if ($tag =~ /^NP$/) {
          $Exp{"type"} = "P";
          $Exp{"number"} = "S";
       }
       elsif  ($tag =~ /^NPS/)  {
           $Exp{"type"} = "P" ;
           $Exp{"number"} = "P";
       }
       if ($tag =~ /^NN$/) {
          $Exp{"type"} = "C";
          $Exp{"number"} = "S";
       }
       elsif  ($tag =~ /^NNS/)  {
           $Exp{"type"} = "C" ;
           $Exp{"number"} = "P";
       }
       $Exp{"gender"} = 0;
       $Exp{"person"} = 3;

   }

   elsif ($tag =~ /(^DT$|^PDT$|^PP\$$)/) {
       (@tmp) = split ("", $tag);
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "DT";
       $Exp{"type"} = 0;
       $Exp{"person"} = 0;
       $Exp{"gender"} = 0;
       $Exp{"number"} = 0;
       $Exp{"possessor"} = 0;
        
   }

  ##mudar tags nos verbos:
   elsif ($tag =~ /(^V|^MD$)/) {

       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "VERB";
       if  ($lemma =~ /^$AUX$/) {
         $Exp{"type"} = "A";
       }
       elsif ($lemma =~ /^$COP$/) {
          $Exp{"type"} = "S";
       }
       else {
          $Exp{"type"} = 0; 
       }
       if ($tag =~ /^VBN/) {
        $Exp{"mode"} = "P";
       }
      
       elsif ($tag =~ /^VBG$/) {
        $Exp{"mode"} = "G";
       }
       else {
          $Exp{"mode"} = 0; 
       }
       if ($tag =~ /^VBD/) {
        $Exp{"tense"} = "S";
	$Exp{"person"} = 0;
	$Exp{"number"} = 0;
	$Exp{"gender"} = 0;
       }
       elsif ($tag =~ /^VBZ/) {
        $Exp{"tense"} = "P";
        $Exp{"person"} = 3;
        $Exp{"number"} = 0;
	$Exp{"gender"} = 0;
       }
       else {
         $Exp{"tense"} = 0;
         $Exp{"person"} = 0;
         $Exp{"number"} = 0;
         $Exp{"gender"} = 0;
       }
   }

     ##simbolos puntuacao:
   #elsif  ($token eq "!")  {
       
  #     $Exp{"lemma"} = $lemma;
  #     $Exp{"token"} = $token;
  #     $Exp{"tag"} =  "Fat";
 #  }

   elsif  ($token eq "�")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Faa";
   }

   elsif  ($token eq ",")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fc";
   }
   elsif  ($token eq "\[")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fca";
   }
   elsif  ($token eq "\]")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fct";
   }
   elsif  ($token eq "\:" || $lemma eq "\:")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fd";
   } 
   elsif  ($token eq "\"")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fe";
   }
   elsif  ($token eq "-")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fg";
   }
   elsif  ($token eq "\/")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fh";
   }
   elsif  ($token eq "�")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fia";
   } 
   # elsif  ($token eq "?")  {
  #     
   #    $Exp{"lemma"} = $lemma;
  #     $Exp{"token"} = $token;
   #    $Exp{"tag"} =  "Flt";
  # } 
   elsif  ($token eq "{")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fla";
   } 
    elsif  ($token eq "}")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Flt";
   } 
   elsif  ($token eq "(")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fpa";
   } 
   elsif  ($token eq ")")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fpt";
   } 
   elsif  ($token eq "\�")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fra";
   } 
   elsif  ($token eq "\�")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Frc";
   } 
   elsif  ($token eq "\.\.\.")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fs";
   } 
   elsif  ($token eq "%")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Ft";
   }  
   elsif  ($token eq "\;")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fx";
   } 

   elsif  ($token eq "[+-=]")  {
       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "Fz";
   }
 
   
   ##particulas
   elsif  ($tag =~ /^RP$/)  {
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "PCLE";
   }

    ##final de frase (.)
   elsif ($token =~ /^\.$|^\?$|^\!$/) {
   # print STDERR "--$lemma -- $tag\n";       
       $Exp{"lemma"} = $lemma;
       $Exp{"token"} = $token;
       $Exp{"tag"} =  "SENT";
       $Exp{"pos"} =  $Pos;
       $Pos=0;
       $FoundFinal=1;
   }
   else {
      $Exp{"lemma"} = $lemma;
      $Exp{"token"} = $token;
      $Exp{"tag"} =  $tag;
   }

  

   ##Colocar a posicao em todos:
     if ($token !~ /^\.$|^\?$|^\!$/) {
       $Exp{"pos"} =  $Pos;
       $Pos++;
    }   

#   if   ($Exp{"tag"} =~ /^Fra$|^Frc$|Fe$/) {

 #  }
 #  else {
       
       my $pipe = "";
       $pipe = "$token\t";
       
       foreach $attrib (sort keys %Exp) {
           $pipe = $pipe . "$attrib:$Exp{$attrib}|" ;
           delete $Exp{$attrib};
       }
       $pipe = $pipe . "\n";
  # }

 }
 ##FIN DO ADAPTER
 ##COMEZO DO PARSER
        $_ = $pipe;
  ($token, $info) = split(" ", $_);

  
  ###Convertimos caracteres significativos na sintaxe de DepPattern em tags especiais
  if ($token =~ /:/) {
      ConvertChar ('\:', "Fd");
  }
  if ($token =~ /\|/) {
      ConvertChar ('\|', "Fz");
  }
  if ($token =~ /\>/) {
      ConvertChar ('\>', "Fz1");
  }
  if ($token =~ /\</) {
      ConvertChar ('\<', "Fz2");
  }



  ##organizamos a informacao de cada token:
   if ($info ne "") {
     (@info) = split ('\|', $info);
     for ($i=0;$i<=$#info;$i++) {
       if ($info[$i] ne "") {
        ($attrib, $value) = split (':', $info[$i]) ;
        $Exp{$attrib} = $value ;
       }
     }
   }

   ##construimos os vectores da oracao
   if ($Exp{"tag"} ne $Border) {
     $Token[$j] = $token ;
     if ($info ne "") {
       $Lemma[$j] = $Exp{"lemma"} ;
       $Tag[$j] = $Exp{"tag"} ;
       $Attributes[$j] = "";
       foreach $at (sort keys %Exp) {
	 if ($at ne "tag"){
	     $Attributes[$j] .= "$at:$Exp{$at}|" ; 
             $ATTR[$j]{$at} = $Exp{$at} ;
         }
       }
       foreach $at (sort keys %Exp) {
	   delete $Exp{$at};
       }
     }

     $j++;
     #print STDERR "$j\r";
   }

   elsif ($Exp{"tag"} eq $Border) {
     $Token[$j] = $token ;
     $Lemma[$j] = $Exp{"lemma"} ;
     $Tag[$j] = $Exp{"tag"} ;
     $Attributes[$j] = "";
     foreach $at (sort keys %Exp) {
         if ($at ne "tag"){
             $Attributes[$j] .= "$at:$Exp{$at}|" ;
             $ATTR[$j]{$at} = $Exp{$at} ;
         }
     }
     foreach $at (sort keys %Exp) {
           delete $Exp{$at};
     }


     ##construimos os strings com a lista de tags-atributos e os token-tags da ora�ao
     for ($i=0;$i<=$#Token;$i++) {

       ReConvertChar ('\:', "Fd", $i);
       ReConvertChar ('\|', "Fz", $i);
       ReConvertChar ('\>', "Fz1", $i);
       ReConvertChar ('\<', "Fz2", $i);

       $listTags .= "$Tag[$i]_${i}_<$Attributes[$i]>" ;
       $seq .= "$Token[$i]_$Tag[$i]_${i}_<$Attributes[$i]>" . " ";

	 
      }##fim do for
     # $seq .= "\." . "_" . $Border ;
     
      $STOP=0;
      #$iteration=0;
      while (!$STOP) {
         $ListInit = $listTags;
         #$iteration++;
        # print STDERR "$iteration\n";


###########################BEGIN GRAMMAR#############################################
# Single: [X] CONJ<lemma:and|or|y|e|et|o|ou>
# Add: coord:no
(@temp) = ($listTags =~ /(?:$X$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($X$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})/$1$2/g;
Add("Head","coord:no",@temp);

# Single: PRP<lemma:so|because|though|if|whether|while> [X]?
# Corr: tag:CONJ, type:S
(@temp) = ($listTags =~ /($PRP${l}lemma:(?:so|because|though|if|whether|while)\|${r})(?:$X$a)?/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($PRP${l}lemma:(?:so|because|though|if|whether|while)\|${r})($X$a)?/$1$2/g;
Corr("Head","tag:CONJ,type:S",@temp);

# Single: ADV<lemma:however> [X]?
# Corr: tag:CONJ, type:S
(@temp) = ($listTags =~ /($ADV${l}lemma:however\|${r})(?:$X$a)?/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($ADV${l}lemma:however\|${r})($X$a)?/$1$2/g;
Corr("Head","tag:CONJ,type:S",@temp);

# Single: PRO<lemma:i|we|he|she|they>
# Corr: type:S
(@temp) = ($listTags =~ /($PRO${l}lemma:(?:i|we|he|she|they)\|${r})/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($PRO${l}lemma:(?:i|we|he|she|they)\|${r})/$1/g;
Corr("Head","type:S",@temp);

# Single: [NOUN] [Fc]? CONJ<lemma:that|which> [NOUN|PRO<type:D|P|I|X>] [VERB]
# Corr: tag:PRO, type:W
(@temp) = ($listTags =~ /(?:$NOUN$a)(?:$Fc$a)?($CONJ${l}lemma:(?:that|which)\|${r})(?:$NOUN$a|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$VERB$a)/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)?($CONJ${l}lemma:(?:that|which)\|${r})($NOUN$a|$PRO${l}type:(?:D|P|I|X)\|${r})($VERB$a)/$1$2$3$4$5/g;
Corr("Head","tag:PRO,type:W",@temp);

# Single: [PRO<lemma:it|there>] [VERB<lemma:be>] [NOUN] PRO<lemma:that>
# Corr: tag:CONJ, type:S
(@temp) = ($listTags =~ /(?:$PRO${l}lemma:(?:it|there)\|${r})(?:$VERB${l}lemma:be\|${r})(?:$NOUN$a)($PRO${l}lemma:that\|${r})/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($PRO${l}lemma:(?:it|there)\|${r})($VERB${l}lemma:be\|${r})($NOUN$a)($PRO${l}lemma:that\|${r})/$1$2$3$4/g;
Corr("Head","tag:CONJ,type:S",@temp);

# Single: [DET] VERB [NOUN]
# Corr: tag:ADJ type:Q
(@temp) = ($listTags =~ /(?:$DET$a)($VERB$a)(?:$NOUN$a)/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($DET$a)($VERB$a)($NOUN$a)/$1$2$3/g;
Corr("Head","tag:ADJ,type:Q",@temp);

# Single: [NOUN] VERB<mode:P>
# Corr: mode:0
(@temp) = ($listTags =~ /(?:$NOUN$a)($VERB${l}mode:P\|${r})/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($VERB${l}mode:P\|${r})/$1$2/g;
Corr("Head","mode:0",@temp);

# Single: PRO<type:X> [ADJ]? [NOUN]
# Corr: tag:DT, type:P
(@temp) = ($listTags =~ /($PRO${l}type:X\|${r})(?:$ADJ$a)?(?:$NOUN$a)/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($PRO${l}type:X\|${r})($ADJ$a)?($NOUN$a)/$1$2$3/g;
Corr("Head","tag:DT,type:P",@temp);

# Single: X<token:a|an> [NOUN|ADJ|ADV]
# Corr: tag:DT, type:I, lemma:=token
(@temp) = ($listTags =~ /($X${l}token:(?:a|an)\|${r})(?:$NOUN$a|$ADJ$a|$ADV$a)/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($X${l}token:(?:a|an)\|${r})($NOUN$a|$ADJ$a|$ADV$a)/$1$2/g;
Corr("Head","tag:DT,type:I,lemma:=token",@temp);

# PunctR: X Fz|Fe
(@temp) = ($listTags =~ /($X$a)($Fz$a|$Fe$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($X$a)($Fz$a|$Fe$a)/$1/g;

# PunctL: Fz|Fe X
(@temp) = ($listTags =~ /($Fz$a|$Fe$a)($X$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($Fz$a|$Fe$a)($X$a)/$2/g;

# <: [VERB<lemma:be|become>] ADV<lemma:$Quant> ADJ [PRP<lemma:than|as>]
# NEXT
# >: VERB<lemma:be|become> [ADV<lemma:$Quant>] ADJ [PRP<lemma:than|as>]
(@temp) = ($listTags =~ /(?:$VERB${l}lemma:(?:be|become)\|${r})($ADV${l}lemma:$Quant\|${r})($ADJ$a)(?:$PRP${l}lemma:(?:than|as)\|${r})/g);
$Rel =  "<";
DepHead_lex($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB${l}lemma:(?:be|become)\|${r})(?:$ADV${l}lemma:$Quant\|${r})($ADJ$a)(?:$PRP${l}lemma:(?:than|as)\|${r})/g);
$Rel =  ">";
HeadDep_lex($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:(?:be|become)\|${r})($ADV${l}lemma:$Quant\|${r})($ADJ$a)($PRP${l}lemma:(?:than|as)\|${r})/$1$4/g;
LEX();

# >: VERB<lemma:be|become>  ADJ [PRP<lemma:than|as>]
(@temp) = ($listTags =~ /($VERB${l}lemma:(?:be|become)\|${r})($ADJ$a)(?:$PRP${l}lemma:(?:than|as)\|${r})/g);
$Rel =  ">";
HeadDep_lex($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:(?:be|become)\|${r})($ADJ$a)($PRP${l}lemma:(?:than|as)\|${r})/$1$3/g;
LEX();

# <: PRP<lemma:in> X<lemma:order> [PRP<lemma:to>]
# NEXT
# <:  [PRP<lemma:in>] X<lemma:order> PRP<lemma:to>
(@temp) = ($listTags =~ /($PRP${l}lemma:in\|${r})($X${l}lemma:order\|${r})(?:$PRP${l}lemma:to\|${r})/g);
$Rel =  "<";
DepHead_lex($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP${l}lemma:in\|${r})($X${l}lemma:order\|${r})($PRP${l}lemma:to\|${r})/g);
$Rel =  "<";
DepHead_lex($Rel,"",@temp);
$listTags =~ s/($PRP${l}lemma:in\|${r})($X${l}lemma:order\|${r})($PRP${l}lemma:to\|${r})/$3/g;
LEX();

# <:  [NOUN|VERB|PRP] X<lemma:next|last|this> NOUN<lemma:$temporal>
# Add: date:yes
(@temp) = ($listTags =~ /(?:$NOUN$a|$VERB$a|$PRP$a)($X${l}lemma:(?:next|last|this)\|${r})($NOUN${l}lemma:$temporal\|${r})/g);
$Rel =  "<";
DepHead_lex($Rel,"",@temp);
$listTags =~ s/($NOUN$a|$VERB$a|$PRP$a)($X${l}lemma:(?:next|last|this)\|${r})($NOUN${l}lemma:$temporal\|${r})/$1$3/g;
LEX();
Add("DepHead_lex","date:yes",@temp);

# Single: [NOUN|VERB|PRP] NOUN<date:yes>
# Corr: tag:DATE
(@temp) = ($listTags =~ /(?:$NOUN$a|$VERB$a|$PRP$a)($NOUN${l}date:yes\|${r})/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($NOUN$a|$VERB$a|$PRP$a)($NOUN${l}date:yes\|${r})/$1$2/g;
Corr("Head","tag:DATE",@temp);

# <: CARD CARD
# Recursivity: 1
(@temp) = ($listTags =~ /($CARD$a)($CARD$a)/g);
$Rel =  "<";
DepHead_lex($Rel,"",@temp);
$listTags =~ s/($CARD$a)($CARD$a)/$2/g;
LEX();
(@temp) = ($listTags =~ /($CARD$a)($CARD$a)/g);
$Rel =  "<";
DepHead_lex($Rel,"",@temp);
$listTags =~ s/($CARD$a)($CARD$a)/$2/g;
LEX();

# AdjnL: ADV<lemma:$Quant> ADV|ADJ
(@temp) = ($listTags =~ /($ADV${l}lemma:$Quant\|${r})($ADV$a|$ADJ$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADV${l}lemma:$Quant\|${r})($ADV$a|$ADJ$a)/$2/g;

# PunctL: [ADJ] Fc ADJ [NOUN]
# NEXT
# AdjnL: ADJ [Fc] ADJ [NOUN]
# Recursivity: 5
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($NOUN$a)/$3$4/g;
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($NOUN$a)/$3$4/g;
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($NOUN$a)/$3$4/g;
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($NOUN$a)/$3$4/g;
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($NOUN$a)/$3$4/g;
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($ADJ$a)(?:$NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($NOUN$a)/$3$4/g;

# CoordL: ADJ CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [ADJ]
# NEXT
# CoordR: [ADJ]  CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> ADJ
# Add: coord:adj
# Inherit: gender, number
(@temp) = ($listTags =~ /($ADJ$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($ADJ$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($ADJ$a)/$2/g;
Inherit("HeadDep","gender,number",@temp);
Add("HeadDep","coord:adj",@temp);

# CoordL: ADJ [Fc] [ADJ] [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [ADJ]
# NEXT
# PunctL:  [ADJ] Fc [ADJ] [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [ADJ]
# Recursivity: 10
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3$4$5$6/g;

# PunctL: [ADJ] Fc CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [ADJ]
# NEXT
# CoordL: ADJ [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [ADJ]
# NEXT
# CoordR:  [ADJ] [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> ADJ
# Add: coord:adj
# Inherit: gender, number
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$ADJ$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$ADJ$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($ADJ$a)/$3/g;
Inherit("HeadDep","gender,number",@temp);
Add("HeadDep","coord:adj",@temp);

# PunctL: [ADJ] Fc CONJ<coord:adj&lemma:and|or|y|e|et|o|ou>
# NEXT
# CoordL: ADJ [Fc] CONJ<coord:adj&lemma:and|or|y|e|et|o|ou>
# Inherit: gender, number
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($CONJ${l}coord:adj\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($CONJ${l}coord:adj\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($CONJ${l}coord:adj\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})/$3/g;
Inherit("DepHead","gender,number",@temp);

# CoordL: ADJ  CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN] [NOUN]
# NEXT
# CoordR: [ADJ]  CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> NOUN [NOUN]
# Add: coord:adj
(@temp) = ($listTags =~ /($ADJ$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)($NOUN$a)/$2$4/g;
Add("HeadDep","coord:adj",@temp);

# CoordL: ADJ [Fc] [ADJ] [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN] [NOUN]
# NEXT
# PunctL:  [ADJ] Fc [ADJ] [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN] [NOUN]
# Recursivity: 3
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($NOUN$a)($NOUN$a)/$3$4$5$6$7/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($NOUN$a)($NOUN$a)/$3$4$5$6$7/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($NOUN$a)($NOUN$a)/$3$4$5$6$7/g;
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($NOUN$a)($NOUN$a)/$3$4$5$6$7/g;

# CoordL: ADJ [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN] [NOUN]
# NEXT
# PunctL: [ADJ] Fc CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN] [NOUN]
# NEXT
# CoordR:  [ADJ] [Fc]? CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> NOUN [NOUN]
# Add: coord:adj
# Inherit: gender, number
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$ADJ$a)(?:$Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($NOUN$a)(?:$NOUN$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)?($CONJ${l}(type:(?:C)|(lemma:and|or|y|e|et|o|ou))\|${r})($NOUN$a)($NOUN$a)/$3$5/g;
Inherit("HeadDep","gender,number",@temp);
Add("HeadDep","coord:adj",@temp);

# PunctL: [ADJ] Fc CONJ<coord:adj&lemma:and|or|y|e|et|o|ou>
# NEXT
# CoordL: ADJ [Fc] CONJ<coord:adj&lemma:and|or|y|e|et|o|ou>
# Inherit: gender, number
(@temp) = ($listTags =~ /(?:$ADJ$a)($Fc$a)($CONJ${l}coord:adj\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADJ$a)(?:$Fc$a)($CONJ${l}coord:adj\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADJ$a)($Fc$a)($CONJ${l}coord:adj\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})/$3/g;
Inherit("DepHead","gender,number",@temp);

# AdjnL: ADJ|CONJ<coord:adj>  NOUN
# Agreement: gender, number
# Recursivity: 1
(@temp) = ($listTags =~ /($ADJ$a|$CONJ${l}coord:adj\|${r})($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"gender,number",@temp);
$listTags =~ s/($ADJ${l}concord:1${r}|$CONJ${l}concord:1${b}coord:adj\|${r})($NOUN${l}concord:1${r})/$2/g;
$listTags =~ s/concord:[01]\|//g;
(@temp) = ($listTags =~ /($ADJ$a|$CONJ${l}coord:adj\|${r})($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"gender,number",@temp);
$listTags =~ s/($ADJ${l}concord:1${r}|$CONJ${l}concord:1${b}coord:adj\|${r})($NOUN${l}concord:1${r})/$2/g;
$listTags =~ s/concord:[01]\|//g;

# AdjnR: NOUN [ADV]? ADJ|CONJ<coord:adj>
# Agreement: gender, number
# Recursivity: 1
(@temp) = ($listTags =~ /($NOUN$a)(?:$ADV$a)?($ADJ$a|$CONJ${l}coord:adj\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"gender,number",@temp);
$listTags =~ s/($NOUN${l}concord:1${r})($ADV$a)?($ADJ${l}concord:1${r}|$CONJ${l}concord:1${b}coord:adj\|${r})/$1$2/g;
$listTags =~ s/concord:[01]\|//g;
(@temp) = ($listTags =~ /($NOUN$a)(?:$ADV$a)?($ADJ$a|$CONJ${l}coord:adj\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"gender,number",@temp);
$listTags =~ s/($NOUN${l}concord:1${r})($ADV$a)?($ADJ${l}concord:1${r}|$CONJ${l}concord:1${b}coord:adj\|${r})/$1$2/g;
$listTags =~ s/concord:[01]\|//g;

# AdjnL: NOUN NOUN
# Recursivity: 1
(@temp) = ($listTags =~ /($NOUN$a)($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($NOUN$a)/$2/g;
(@temp) = ($listTags =~ /($NOUN$a)($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($NOUN$a)/$2/g;

# AdjnL: CARD NOUN
# Recursivity 1
(@temp) = ($listTags =~ /($CARD$a)($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($CARD$a)($NOUN$a)/$2/g;

# CprepL: NOUN POS NOUN
(@temp) = ($listTags =~ /($NOUN$a)($POS$a)($NOUN$a)/g);
$Rel =  "CprepL";
DepRelHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($POS$a)($NOUN$a)/$3/g;

# Single: [DET] ADJ [PRP]
# Corr: tag:NOUN
(@temp) = ($listTags =~ /(?:$DET$a)($ADJ$a)(?:$PRP$a)/g);
$Rel =  "Single";
Head($Rel,"",@temp);
$listTags =~ s/($DET$a)($ADJ$a)($PRP$a)/$1$2$3/g;
Corr("Head","tag:NOUN",@temp);

# AdjnL: [PRP<lemma:as>] ADV [DET]  NOUN
(@temp) = ($listTags =~ /(?:$PRP${l}lemma:as\|${r})($ADV$a)(?:$DET$a)($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($PRP${l}lemma:as\|${r})($ADV$a)($DET$a)($NOUN$a)/$1$3$4/g;

# SpecL: DET DET [NOUN]
# NEXT
# SpecL: [DET] DET NOUN
(@temp) = ($listTags =~ /($DET$a)($DET$a)(?:$NOUN$a)/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$DET$a)($DET$a)($NOUN$a)/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($DET$a)($DET$a)($NOUN$a)/$3/g;

# AdjnL: [DET] VERB<mode:P> NOUN
# NEXT
# SpecL: DET [VERB<mode:P>] NOUN
(@temp) = ($listTags =~ /(?:$DET$a)($VERB${l}mode:P\|${r})($NOUN$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($DET$a)(?:$VERB${l}mode:P\|${r})($NOUN$a)/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($DET$a)($VERB${l}mode:P\|${r})($NOUN$a)/$3/g;

# SpecL: DET CARD|DATE
(@temp) = ($listTags =~ /($DET$a)($CARD$a|$DATE$a)/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($DET$a)($CARD$a|$DATE$a)/$2/g;

# SpecL: DET NOUN|PRO
# Recursivity: 1
(@temp) = ($listTags =~ /($DET$a)($NOUN$a|$PRO$a)/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($DET$a)($NOUN$a|$PRO$a)/$2/g;
(@temp) = ($listTags =~ /($DET$a)($NOUN$a|$PRO$a)/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($DET$a)($NOUN$a|$PRO$a)/$2/g;

# ClitR: VERB PRO<token:$cliticopers>
# Recursivity: 1
(@temp) = ($listTags =~ /($VERB$a)($PRO${l}token:$cliticopers\|${r})/g);
$Rel =  "ClitR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($PRO${l}token:$cliticopers\|${r})/$1/g;
(@temp) = ($listTags =~ /($VERB$a)($PRO${l}token:$cliticopers\|${r})/g);
$Rel =  "ClitR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($PRO${l}token:$cliticopers\|${r})/$1/g;

# >: VERB PCLE
(@temp) = ($listTags =~ /($VERB$a)($PCLE$a)/g);
$Rel =  ">";
HeadDep_lex($Rel,"",@temp);
$listTags =~ s/($VERB$a)($PCLE$a)/$1/g;
LEX();

# VSpecL: VERB<type:S> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB<mode:P>
# Add: voice:passive
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB${l}type:S\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB${l}mode:P\|${r})/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB${l}type:S\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB${l}mode:P\|${r})/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);
Add("DepHead","voice:passive",@temp);

# VSpecL: VERB<(type:S)|(lemma:ser|�tre|be)> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB<mode:P>
# Add: voice:passive
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB${l}type:S\|${r}|$VERB${l}lemma:(?:ser|�tre|be)\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB${l}mode:P\|${r})/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB${l}type:S\|${r}|$VERB${l}lemma:(?:ser|�tre|be)\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB${l}mode:P\|${r})/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);
Add("DepHead","voice:passive",@temp);

# VSpecL: VERB<(type:A)|(lemma:ter|haver|haber|avoir|have)> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB<mode:P>
# Add: type:perfect
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB${l}type:A\|${r}|$VERB${l}lemma:(?:ter|haver|haber|avoir|have)\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB${l}mode:P\|${r})/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB${l}type:A\|${r}|$VERB${l}lemma:(?:ter|haver|haber|avoir|have)\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB${l}mode:P\|${r})/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);
Add("DepHead","type:perfect",@temp);

# VSpecL: VERB<lemma:do> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB${l}lemma:do\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB$a)/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:do\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB$a)/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);

# VSpecL: VERB<lemma:$VModalEN> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB${l}lemma:$VModalEN\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB$a)/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:$VModalEN\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB$a)/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);

# VSpecL: VERB<lemma:be> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB<mode:G>
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB${l}lemma:be\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB${l}mode:G\|${r})/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:be\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB${l}mode:G\|${r})/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);

# VSpecL: [VERB] [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? PRP<lemma:$PrepLocs> [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB
# NEXT
# VSpecL: VERB [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [PRP<lemma:$PrepLocs>] [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($PRP${l}lemma:$PrepLocs\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB$a)/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$PRP${l}lemma:$PrepLocs\|${r})(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB$a)/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($PRP${l}lemma:$PrepLocs\|${r})($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB$a)/$2$3$4$5$6$7$8$9$10$11$13$14$15$16$17$18$19$20$21$22$23/g;
Inherit("DepHead","mode,person,tense,number",@temp);

# >: VERB [NOUN]? PCLE
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUN$a)?($PCLE$a)/g);
$Rel =  ">";
HeadDep_lex($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUN$a)?($PCLE$a)/$1$2/g;
LEX();

# >: VERB<lemma:$VerbsPCLE> [NOUN]? X<lemma:$PCLE>
(@temp) = ($listTags =~ /($VERB${l}lemma:$VerbsPCLE\|${r})(?:$NOUN$a)?($X${l}lemma:$PCLE\|${r})/g);
$Rel =  ">";
HeadDep_lex($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:$VerbsPCLE\|${r})($NOUN$a)?($X${l}lemma:$PCLE\|${r})/$1$2/g;
LEX();

# VSpecL: VERB [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? [ADV]? VERB<mode:G>
# Inherit: mode, person, tense, number
(@temp) = ($listTags =~ /($VERB$a)(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?(?:$ADV$a)?($VERB${l}mode:G\|${r})/g);
$Rel =  "VSpecL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($ADV$a)?($VERB${l}mode:G\|${r})/$2$3$4$5$6$7$8$9$10$11$12/g;
Inherit("DepHead","mode,person,tense,number",@temp);

# PunctL: [ADV<pos:0>] Fc VERB
# NEXT
# AdjnL: ADV<pos:0> [Fc] VERB
(@temp) = ($listTags =~ /(?:$ADV${l}pos:0\|${r})($Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($ADV${l}pos:0\|${r})(?:$Fc$a)($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADV${l}pos:0\|${r})($Fc$a)($VERB$a)/$3/g;

# PunctL: Fc [ADV] [Fc] VERB
# NEXT
# PunctL: [Fc] [ADV] Fc VERB
# NEXT
# AdjnL: [Fc] ADV [Fc] VERB
(@temp) = ($listTags =~ /($Fc$a)(?:$ADV$a)(?:$Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)(?:$ADV$a)($Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)($ADV$a)(?:$Fc$a)($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($Fc$a)($ADV$a)($Fc$a)($VERB$a)/$4/g;

# PunctR:  VERB [Fc] [ADV] Fc
# NEXT
# PunctR: VERB Fc [ADV] [Fc]
# NEXT
# AdjnR: VERB [Fc] ADV [Fc]
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$ADV$a)($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)($Fc$a)(?:$ADV$a)(?:$Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)($ADV$a)(?:$Fc$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($ADV$a)($Fc$a)/$1/g;

# AdjnL:  ADV  VERB
# Recursivity: 1
(@temp) = ($listTags =~ /($ADV$a)($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADV$a)($VERB$a)/$2/g;
(@temp) = ($listTags =~ /($ADV$a)($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($ADV$a)($VERB$a)/$2/g;

# AdjnR: VERB [NOUN|PRO<type:D|P|I|X>]? ADV
# Recursivity: 1
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUN$a|$PRO${l}type:(?:D|P|I|X)\|${r})?($ADV$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUN$a|$PRO${l}type:(?:D|P|I|X)\|${r})?($ADV$a)/$1$2/g;
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUN$a|$PRO${l}type:(?:D|P|I|X)\|${r})?($ADV$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUN$a|$PRO${l}type:(?:D|P|I|X)\|${r})?($ADV$a)/$1$2/g;

# CoordL: PRP [NOUN] CONJ<lemma:and|or|y|e|et|o|ou> [PRP] [NOUN]
# NEXT
# TermR: [PRP] [NOUN] [CONJ<lemma:and|or|y|e|et|o|ou>] PRP NOUN
# NEXT
# TermR: PRP NOUN [CONJ<lemma:and|or|y|e|et|o|ou>] [PRP] [NOUN]
# NEXT
# CoordR: [PRP] [NOUN] CONJ<lemma:and|or|y|e|et|o|ou> PRP [NOUN]
# Add: coord:cprep
(@temp) = ($listTags =~ /($PRP$a)(?:$NOUN$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP$a)(?:$NOUN$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($PRP$a)($NOUN$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP$a)(?:$NOUN$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($PRP$a)($NOUN$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/$3/g;
Add("HeadDep","coord:cprep",@temp);

# TermR: PRP NOUN [Fc] [PRP] [NOUN] [Fc] [CONJ<lemma:and|or|y|e|et|o|ou>] [PRP] [NOUN]
# NEXT
# PunctL: [PRP] [NOUN] Fc [PRP] [NOUN] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [PRP] [NOUN]
# NEXT
# CoordL: PRP [NOUN] [Fc] [PRP] [NOUN] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [PRP] [NOUN]
# Recursivity: 3
(@temp) = ($listTags =~ /($PRP$a)($NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP$a)(?:$NOUN$a)($Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
$listTags =~ s/($PRP$a)($NOUN$a)($Fc$a)($PRP$a)($NOUN$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/$4$5$6$7$8$9/g;
(@temp) = ($listTags =~ /($PRP$a)($NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP$a)(?:$NOUN$a)($Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
$listTags =~ s/($PRP$a)($NOUN$a)($Fc$a)($PRP$a)($NOUN$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/$4$5$6$7$8$9/g;
(@temp) = ($listTags =~ /($PRP$a)($NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP$a)(?:$NOUN$a)($Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
$listTags =~ s/($PRP$a)($NOUN$a)($Fc$a)($PRP$a)($NOUN$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/$4$5$6$7$8$9/g;
(@temp) = ($listTags =~ /($PRP$a)($NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$PRP$a)(?:$NOUN$a)($Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
$listTags =~ s/($PRP$a)($NOUN$a)($Fc$a)($PRP$a)($NOUN$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/$4$5$6$7$8$9/g;

# CoordL: [Fc]? PRP [NOUN] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [PRP] [NOUN]
# NEXT
# TermR: [Fc]? [PRP] [NOUN] [Fc] [CONJ<lemma:and|or|y|e|et|o|ou>] PRP NOUN
# NEXT
# TermR: [Fc]? PRP NOUN [Fc] [CONJ<lemma:and|or|y|e|et|o|ou>] [PRP] [NOUN]
# NEXT
# PunctL: [Fc]? [PRP] [NOUN] Fc CONJ<lemma:and|or|y|e|et|o|ou> [PRP] [NOUN]
# NEXT
# CoordR: [Fc]? [PRP] [NOUN] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> PRP [NOUN]
# Add: coord:cprep
(@temp) = ($listTags =~ /(?:$Fc$a)?($PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)?(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)?($PRP$a)($NOUN$a)(?:$Fc$a)(?:$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)?(?:$PRP$a)(?:$NOUN$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$PRP$a)(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)?(?:$PRP$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)(?:$NOUN$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($Fc$a)?($PRP$a)($NOUN$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($PRP$a)($NOUN$a)/$1$5/g;
Add("HeadDep","coord:cprep",@temp);

# CprepR: [NOUNSINGLE] [PRP] [NOUNSINGLE] [PRP] [NOUNSINGLE] [PRP] [NOUNSINGLE] [PRP] NOUNSINGLE PRP<lemma:$PrepRA> NOUNSINGLE|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /(?:$NOUNSINGLE$a)(?:$PRP$a)(?:$NOUNSINGLE$a)(?:$PRP$a)(?:$NOUNSINGLE$a)(?:$PRP$a)(?:$NOUNSINGLE$a)(?:$PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/$1$2$3$4$5$6$7$8$9/g;

# CprepR: [NOUNSINGLE] [PRP] [NOUNSINGLE] [PRP] [NOUNSINGLE] [PRP] NOUNSINGLE PRP<lemma:$PrepRA> NOUNSINGLE|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /(?:$NOUNSINGLE$a)(?:$PRP$a)(?:$NOUNSINGLE$a)(?:$PRP$a)(?:$NOUNSINGLE$a)(?:$PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/$1$2$3$4$5$6$7/g;

# CprepR: [NOUNSINGLE] [PRP] [NOUNSINGLE] [PRP] NOUNSINGLE PRP<lemma:$PrepRA> NOUNSINGLE|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /(?:$NOUNSINGLE$a)(?:$PRP$a)(?:$NOUNSINGLE$a)(?:$PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/$1$2$3$4$5/g;

# CprepR: [NOUNSINGLE] [PRP] NOUNSINGLE PRP<lemma:$PrepRA> NOUNSINGLE|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /(?:$NOUNSINGLE$a)(?:$PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNSINGLE$a)($PRP$a)($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/$1$2$3/g;

# CprepR: NOUNSINGLE PRP<lemma:$PrepRA> NOUNSINGLE|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CprepR: CARD<lemma:uno|one|un|um> PRP NOUNSINGLE|PRO<type:D|P|I|X>
# Add: tag:PRO
(@temp) = ($listTags =~ /($CARD${l}lemma:(?:uno|one|un|um)\|${r})($PRP$a)($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($CARD${l}lemma:(?:uno|one|un|um)\|${r})($PRP$a)($NOUNSINGLE$a|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;
Add("HeadRelDep","tag:PRO",@temp);

# CprepR: NOUNSINGLE PRP<lemma:$PrepRA> VERB<mode:G>
(@temp) = ($listTags =~ /($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($VERB${l}mode:G\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNSINGLE$a)($PRP${l}lemma:$PrepRA\|${r})($VERB${l}mode:G\|${r})/$1/g;

# CoordL: NOUN CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN]
# NEXT
# CoordR: [NOUN]  CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> NOUN
# Add: coord:noun
(@temp) = ($listTags =~ /($NOUN$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$2/g;
Add("HeadDep","coord:noun",@temp);

# CoordL: NOUN [Fc] [NOUN] [Fc] CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN]
# NEXT
# PunctL:  [NOUN] Fc [NOUN] [Fc] CONJ<(type:C)|(lemma:and|or|y|e|et|o|ou)> [NOUN]
# Add: coord:yes
# Recursivity: 10
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)(?:$NOUN$a)(?:$Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($NOUN$a)($Fc$a)($CONJ${l}type:C\|${r}|$CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3$4$5$6/g;
Add("DepHead","coord:yes",@temp);

# CoordL: NOUN [Fc] CONJ<coord:yes&lemma:and|or|y|e|et|o|ou> [NOUN]
# NEXT
# PunctL: [NOUN] Fc CONJ<coord:yes&lemma:and|or|y|e|et|o|ou> [NOUN]
# NEXT
# CoordR:  [NOUN] [Fc] CONJ<coord:yes&lemma:and|or|y|e|et|o|ou> NOUN
# Add: coord:noun
(@temp) = ($listTags =~ /($NOUN$a)(?:$Fc$a)($CONJ${l}coord:yes\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($Fc$a)($CONJ${l}coord:yes\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$NOUN$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)(?:$Fc$a)($CONJ${l}coord:yes\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($Fc$a)($CONJ${l}coord:yes\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($NOUN$a)/$3/g;
Add("HeadDep","coord:noun",@temp);

# PunctL: [NOUNCOORD|PRO<type:D|P|I|S>] Fc|Fpa|Fca NOUNCOORD|PRO<type:D|P|I|X>|CARD [Fc|Fpt|Fct]
# NEXT
# PunctR: [NOUNCOORD|PRO<type:D|P|I|S>] [Fc|Fpa|Fca] NOUNCOORD|PRO<type:D|P|I|X>|CARD Fc|Fpt|Fct
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|S> [Fc|Fpa|Fca] NOUNCOORD|PRO<type:D|P|I|X>|CARD [Fc|Fpt|Fct]
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a|$Fca$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)(?:$Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a|$Fca$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)($Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a|$Fca$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)(?:$Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a|$Fca$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)($Fc$a|$Fpt$a|$Fct$a)/$1/g;

# PunctL: [NOUNCOORD|PRO<type:D|P|I|S>] Fc|Fpa|Fca [PRP] NOUNCOORD|PRO<type:D|P|I|X>|CARD [Fc|Fpt|Fct]
# NEXT
# PunctR: [NOUNCOORD|PRO<type:D|P|I|S>] [Fc|Fpa|Fca] [PRP] NOUNCOORD|PRO<type:D|P|I|X>|CARD Fc|Fpt|Fct
# NEXT
# CprepR: NOUNCOORD|PRO<type:D|P|I|S> [Fc|Fpa|Fca] PRP NOUNCOORD|PRO<type:D|P|I|X>|CARD [Fc|Fpt|Fct]
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a|$Fca$a)(?:$PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)(?:$Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a|$Fca$a)(?:$PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)($Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a|$Fca$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)(?:$Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a|$Fca$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$CARD$a)($Fc$a|$Fpt$a|$Fct$a)/$1/g;

# AdjnR: NOUNCOORD|PRO<type:D|P|I|S> [Fc|Fpa|Fca] VERB<mode:P> [X]? [X]? [X]? [X]? [X]? [X]? [X]? [X]? [X]? [X]? [Fc|Fpt|Fct]
# NoUniq
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a|$Fca$a)($VERB${l}mode:P\|${r})(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$Fc$a|$Fpt$a|$Fct$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a|$Fca$a)($VERB${l}mode:P\|${r})($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($Fc$a|$Fpt$a|$Fct$a)/$1$2$3$4$5$6$7$8$9$10$11$12$13$14/g;

# SubjL: [NOUNCOORD] PRO<type:R|W> VERB|CONJ<coord:verb>
# NEXT
# AdjnR: NOUNCOORD [PRO<type:R|W>] VERB|CONJ<coord:verb>
# NoUniq
(@temp) = ($listTags =~ /(?:$NOUNCOORD)($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD)(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD)($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/$1$2$3/g;

# DobjL: [NOUNCOORD] PRO<type:R|W> [NOUNCOORD|PRO<type:D|P|I|S>] VERB|CONJ<coord:verb>
# NEXT
# AdjnR: NOUNCOORD [PRO<type:R|W>] [NOUNCOORD|PRO<type:D|P|I|S>] VERB|CONJ<coord:verb>
# NoUniq
(@temp) = ($listTags =~ /(?:$NOUNCOORD)($PRO${l}type:(?:R|W)\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "DobjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD)(?:$PRO${l}type:(?:R|W)\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD)($PRO${l}type:(?:R|W)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/$1$2$3$4/g;

# CircL: [NOUNCOORD|PRO<type:D|P|I|X>]  PRP PRO<type:R|W> VERB|CONJ<coord:verb>
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|X> [PRP] [PRO<type:R|W>] VERB|CONJ<coord:verb>
# NoUniq
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "CircL";
RelDepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$PRP$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/$1$2$3$4/g;

# AdjnR: NOUNCOORD|PRO<type:D|P|I|X> [Fc]? VERB<mode:[GP]>|CONJ<coord:verb>
# NoUniq
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?($VERB${l}mode:[GP]\|${r}|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?($VERB${l}mode:[GP]\|${r}|$CONJ${l}coord:verb\|${r})/$1$2$3/g;

# CircR: VERB<lemma:$PTa> [NOUNCOORD|PRO<type:D|P|I|X>] PRP<lemma:a> NOUNCOORD|PRO<type:D|P|I|X>|VERB<mode:N>|ADV
(@temp) = ($listTags =~ /($VERB${l}lemma:$PTa\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP${l}lemma:a\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$VERB${l}mode:N\|${r}|$ADV$a)/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:$PTa\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP${l}lemma:a\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$VERB${l}mode:N\|${r}|$ADV$a)/$1$2/g;

# CircR: VERB<mode:P> [NOUNCOORD|PRO<type:D|P|I|X>] PRP<lemma:por|by> NOUNCOORD|PRO<type:D|P|I|X>|ADV
(@temp) = ($listTags =~ /($VERB${l}mode:P\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP${l}lemma:(?:por|by)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$ADV$a)/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}mode:P\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP${l}lemma:(?:por|by)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}|$ADV$a)/$1$2/g;

# CircR: VERB [NOUNCOORD|PRO<type:D|P|I|X>] PRP<lemma:$PrepMA> CARD|DATE
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP${l}lemma:$PrepMA\|${r})($CARD$a|$DATE$a)/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP${l}lemma:$PrepMA\|${r})($CARD$a|$DATE$a)/$1$2/g;

# CprepR: CARD PRP<lemma:de|entre|sobre|of|about|between> NOUNCOORD|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /($CARD$a)($PRP${l}lemma:(?:de|entre|sobre|of|about|between)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($CARD$a)($PRP${l}lemma:(?:de|entre|sobre|of|about|between)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CprepR: PRO<type:P> PRP<lemma:de|of> NOUNCOORD|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /($PRO${l}type:P\|${r})($PRP${l}lemma:(?:de|of)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($PRO${l}type:P\|${r})($PRP${l}lemma:(?:de|of)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CprepR: NOUNCOORD [PRP] [PRO<type:D|P|I|X>] PRP NOUNCOORD|ADV
# NEXT
# CprepR: NOUNCOORD PRP PRO<type:D|P|I|X> [PRP] [NOUNCOORD]|ADV
(@temp) = ($listTags =~ /($NOUNCOORD)(?:$PRP$a)(?:$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($NOUNCOORD|$ADV$a)/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD)($PRP$a)($PRO${l}type:(?:D|P|I|X)\|${r})(?:$PRP$a)([NOUNCOORD]|ADV)/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD)($PRP$a)($PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)([NOUNCOORD]|ADV)/$1/g;

# PrepR: VERB [NOUNCOORD|PRO<type:D|P|I|X>] CONJ<coord:cprep>
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($CONJ${l}coord:cprep\|${r})/g);
$Rel =  "PrepR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($CONJ${l}coord:cprep\|${r})/$1$2/g;

# PrepR: NOUNCOORD|PRO<type:D|P|I|X> CONJ<coord:cprep>
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($CONJ${l}coord:cprep\|${r})/g);
$Rel =  "PrepR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($CONJ${l}coord:cprep\|${r})/$1/g;

# SubjL: [VERB] [X<lemma:what>] NOUNCOORD|PRO<type:D|P|I|S> VERB
# NEXT
# DobjL: [VERB] X<lemma:what> [NOUNCOORD|PRO<type:D|P|I|S] VERB
# Add: compl:yes
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$X${l}lemma:what\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB$a)/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($X${l}lemma:what\|${r})(?:$NOUNCOORD|$PRO$a${l}type:D|P|I|S)($VERB$a)/g);
$Rel =  "DobjL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($X${l}lemma:what\|${r})($NOUNCOORD|$PRO$a${l}type:D|P|I|S)($VERB$a)/$1$4/g;
Add("DepHead","compl:yes",@temp);

# AdjnL:  [VERB] [X<lemma:where|when>] NOUNCOORD|PRO<type:D|P|I|S> VERB
# NEXT
# DobjL: [VERB] X<lemma:where|when> [NOUNCOORD|PRO<type:D|P|I|S] VERB
# Add: compl:yes
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$X${l}lemma:(?:where|when)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($X${l}lemma:(?:where|when)\|${r})(?:$NOUNCOORD|$PRO$a${l}type:D|P|I|S)($VERB$a)/g);
$Rel =  "DobjL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($X${l}lemma:(?:where|when)\|${r})($NOUNCOORD|$PRO$a${l}type:D|P|I|S)($VERB$a)/$1$4/g;
Add("DepHead","compl:yes",@temp);

# CircR: [VERB] [NOUN]  VERB<compl:yes&mode:[^PNG]> PRP NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# SubjL: [VERB] NOUN VERB<compl:yes&mode:[^PNG]>  [PRP NOUNCOORD|PRO<type:D|P|I|X>]
# NEXT
# DobjComplR: VERB [NOUN]? VERB<compl:yes&mode:[^PNG]>  [PRP NOUNCOORD|PRO<type:D|P|I|X>]
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$NOUN$a)($VERB${l}compl:yes\|${b}mode:[^PNG]\|${r})($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($NOUN$a)($VERB${l}compl:yes\|${b}mode:[^PNG]\|${r})([PRP)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}])/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUN$a)?($VERB${l}compl:yes\|${b}mode:[^PNG]\|${r})([PRP)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}])/g);
$Rel =  "DobjComplR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUN$a)?($VERB${l}compl:yes\|${b}mode:[^PNG]\|${r})([PRP)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}])/$1/g;

# CircR: [VERB<lemma:say|think>]  [NOUN]  VERB<mode:[^PNG]> PRP NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# SubjL: [VERB<lemma:say|think>] NOUN VERB<mode:[^PNG]> [PRP NOUNCOORD|PRO<type:D|P|I|X>]
# NEXT
# DobjComplR: VERB<lemma:say|think> [NOUN]? VERB<mode:[^PNG]>  [PRP NOUNCOORD|PRO<type:D|P|I|X>]
(@temp) = ($listTags =~ /(?:$VERB${l}lemma:(?:say|think)\|${r})(?:$NOUN$a)($VERB${l}mode:[^PNG]\|${r})($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB${l}lemma:(?:say|think)\|${r})($NOUN$a)($VERB${l}mode:[^PNG]\|${r})([PRP)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}])/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB${l}lemma:(?:say|think)\|${r})(?:$NOUN$a)?($VERB${l}mode:[^PNG]\|${r})([PRP)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}])/g);
$Rel =  "DobjComplR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:(?:say|think)\|${r})($NOUN$a)?($VERB${l}mode:[^PNG]\|${r})([PRP)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r}])/$1/g;

# Dobj2R: VERB NOUNCOORD|PRO<type:P|X> [NOUNCOORD|PRO<type:D|I|X>]
# NEXT
# DobjR: VERB [NOUNCOORD|PRO<type:P|X>] NOUNCOORD|PRO<type:D|I|X>
(@temp) = ($listTags =~ /($VERB$a)($NOUNCOORD|$PRO${l}type:(?:P|X)\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|I|X)\|${r})/g);
$Rel =  "Dobj2R";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUNCOORD|$PRO${l}type:(?:P|X)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|I|X)\|${r})/g);
$Rel =  "DobjR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUNCOORD|$PRO${l}type:(?:P|X)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|I|X)\|${r})/$1/g;

# CircR: [VERB<lemma:be>] [ADJ|CONJ<coord:adj>] [PRP] VERB [NOUNCOORD|PRO<type:D|P|I|X>]? PRP NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# DobjR: [VERB<lemma:be>] [ADJ|CONJ<coord:adj>] [PRP] VERB NOUNCOORD|PRO<type:D|P|I|X> [PRP]? [NOUNCOORD|PRO<type:D|P|I|X>]?
# NEXT
# CprepR: [VERB<lemma:be>] ADJ|CONJ<coord:adj> PRP VERB [NOUNCOORD|PRO<type:D|P|I|X>]? [PRP]? [NOUNCOORD|PRO<type:D|P|I|X>]?
(@temp) = ($listTags =~ /(?:$VERB${l}lemma:be\|${r})(?:$ADJ$a|$CONJ${l}coord:adj\|${r})(?:$PRP$a)($VERB$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})?($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB${l}lemma:be\|${r})(?:$ADJ$a|$CONJ${l}coord:adj\|${r})(?:$PRP$a)($VERB$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$PRP$a)?(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})?/g);
$Rel =  "DobjR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB${l}lemma:be\|${r})($ADJ$a|$CONJ${l}coord:adj\|${r})($PRP$a)($VERB$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})?(?:$PRP$a)?(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})?/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:be\|${r})($ADJ$a|$CONJ${l}coord:adj\|${r})($PRP$a)($VERB$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})?($PRP$a)?($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})?/$1$2/g;

# AdjnR: NOUN [VERB<lemma:be>] NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# AtrR: [NOUN] VERB<lemma:be> NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# SubjL: NOUN VERB<lemma:be> [NOUNCOORD|PRO<type:D|P|I|X>]
# AdjnR: NOUN [VERB<lemma:be>] ADJ|CONJ<coord:adj>
# NEXT
# AtrR: [NOUN] VERB<lemma:be> ADJ|CONJ<coord:adj>
# NEXT
# SubjL: NOUN VERB<lemma:be> [ADJ|CONJ<coord:adj>]
(@temp) = ($listTags =~ /($NOUN$a)(?:$VERB${l}lemma:be\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($VERB${l}lemma:be\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "AtrR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUN$a)($VERB${l}lemma:be\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUN$a)($VERB${l}lemma:be\|${r})($ADJ$a|$CONJ${l}coord:adj\|${r})/g);
$Rel =  "AtrR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUN$a)($VERB${l}lemma:be\|${r})(?:$ADJ$a|$CONJ${l}coord:adj\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN$a)($VERB${l}lemma:be\|${r})($ADJ$a|$CONJ${l}coord:adj\|${r})/$2/g;

# AtrR: VERB<lemma:be> NOUNCOORD|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /($VERB${l}lemma:be\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "AtrR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:be\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# AtrR: VERB ADJ|CONJ<coord:adj>
(@temp) = ($listTags =~ /($VERB$a)($ADJ$a|$CONJ${l}coord:adj\|${r})/g);
$Rel =  "AtrR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($ADJ$a|$CONJ${l}coord:adj\|${r})/$1/g;

# DobjR: VERB NOUNCOORD|PRO<type:D|P|I|X>
(@temp) = ($listTags =~ /($VERB$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "DobjR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CoordL: VERB CONJ<coord:no&lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# CoordR: [VERB]  CONJ<coord:no&lemma:and|or|y|e|et|o|ou> VERB
# Add: coord:verb
# Inherit: mode, tense
(@temp) = ($listTags =~ /($VERB$a)($CONJ${l}coord:no\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($CONJ${l}coord:no\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($CONJ${l}coord:no\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$2/g;
Inherit("HeadDep","mode,tense",@temp);
Add("HeadDep","coord:verb",@temp);

# CoordL: VERB [Fc] [VERB] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# PunctL:  [VERB] Fc [VERB] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [VERB]
# Add: coord:verb
# Recursivity: 5
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);

# PunctL: [VERB] Fc CONJ<coord:verb&lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# CoordL: VERB [Fc] CONJ<coord:verb&lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# CoordR:  [VERB] [Fc] CONJ<coord:verb&lemma:and|or|y|e|et|o|ou> VERB
# Add: coord:verb
# Inherit: mode, tense
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3/g;
Inherit("HeadDep","mode,tense",@temp);
Add("HeadDep","coord:verb",@temp);

# CircR: [VERB|CONJ<coord:verb>] [PRP] VERB|CONJ<coord:verb> [PRP] [CARD|NOUNCOORD|PRO<type:D|P|I|X>] PRP CARD|NOUNCOORD|PRO<type:D|P|I|X>
# Recursivity: 1
(@temp) = ($listTags =~ /(?:$VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)(?:$CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1$2$3$4$5/g;
(@temp) = ($listTags =~ /(?:$VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)(?:$CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1$2$3$4$5/g;

# CircR: [VERB|CONJ<coord:verb>] [PRP] VERB|CONJ<coord:verb> PRP CARD|NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# CircR: VERB|CONJ<coord:verb> PRP VERB|CONJ<coord:verb> [PRP] [CARD|NOUNCOORD|PRO<type:D|P|I|X>]
(@temp) = ($listTags =~ /(?:$VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)(?:$CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CircR: [VERB|CONJ<coord:verb>] [PRP] VERB|CONJ<coord:verb> PRP CARD|NOUNCOORD|PRO<type:D|P|I|X>
# NEXT
# CircR: VERB|CONJ<coord:verb> PRP VERB|CONJ<coord:verb> [PRP] [CARD|NOUNCOORD|PRO<type:D|P|I|X>]
(@temp) = ($listTags =~ /(?:$VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})(?:$PRP$a)(?:$CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($CARD$a|$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CircR: VERB|CONJ<coord:verb> PRP VERB|ADV|CARD
# Recursivity: 1
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$ADV$a|$CARD$a)/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$ADV$a|$CARD$a)/$1/g;
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$ADV$a|$CARD$a)/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($VERB$a|$ADV$a|$CARD$a)/$1/g;

# CircR: VERB|CONJ<coord:verb> PRP NOUNCOORD|PRO<type:D|P|I|X>
# Recursivity: 1
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})/$1/g;

# CircR: VERB|CONJ<coord:verb> [X]? [X]? [X]? [X]? [X]? [X]? [X]? [X]? [X]? [X]? PRP<lemma:to> VERB|CONJ<coord:verb>
(@temp) = ($listTags =~ /($VERB$a|$CONJ${l}coord:verb\|${r})(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?(?:$X$a)?($PRP${l}lemma:to\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a|$CONJ${l}coord:verb\|${r})($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($X$a)?($PRP${l}lemma:to\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})/$1$2$3$4$5$6$7$8$9$10$11/g;

# PunctR: VERB Fc [PRP] [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]?
# NEXT
# PunctR: VERB [Fc] [PRP] [NOUNCOORD|PRO<type:D|P|I|X>] Fc
# NEXT
# TermR: [VERB] [Fc] PRP NOUNCOORD|PRO<type:D|P|I|X> [Fc]?
# NEXT
# CircR: VERB [Fc] PRP [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]?
# Recursivity:2
(@temp) = ($listTags =~ /($VERB$a)($Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)($PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?/$1/g;
(@temp) = ($listTags =~ /($VERB$a)($Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)($PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?/$1/g;
(@temp) = ($listTags =~ /($VERB$a)($Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "TermR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)($PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?/g);
$Rel =  "CircR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?/$1/g;

# PunctL: [PRP<pos:0>] [NOUNCOORD|PRO<type:D|P|I|X>] Fc  VERB
# NEXT
# CircL: PRP<pos:0> NOUNCOORD|PRO<type:D|P|I|X> [Fc]?  VERB
(@temp) = ($listTags =~ /(?:$PRP${l}pos:0\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($PRP${l}pos:0\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?($VERB$a)/g);
$Rel =  "CircL";
RelDepHead($Rel,"",@temp);
$listTags =~ s/($PRP${l}pos:0\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?($VERB$a)/$4/g;

# PunctL: Fc [PRP] [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]  VERB
# NEXT
# PunctL: [Fc] [PRP] [NOUNCOORD|PRO<type:D|P|I|X>] Fc  VERB
# NEXT
# CircL: [Fc] PRP NOUNCOORD|PRO<type:D|P|I|X> [Fc]  VERB
(@temp) = ($listTags =~ /($Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)(?:$PRP$a)(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)($VERB$a)/g);
$Rel =  "CircL";
RelDepHead($Rel,"",@temp);
$listTags =~ s/($Fc$a)($PRP$a)($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)($VERB$a)/$5/g;

# AdjnR:  VERB<mode:[^PNG]> DATE
(@temp) = ($listTags =~ /($VERB${l}mode:[^PNG]\|${r})($DATE$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}mode:[^PNG]\|${r})($DATE$a)/$1/g;

# PunctL: Fc [DATE] VERB<mode:[^PNG]>
# NEXT
# AdjnL:  [Fc]? DATE VERB<mode:[^PNG]>
(@temp) = ($listTags =~ /($Fc$a)(?:$DATE$a)($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)?($DATE$a)($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($Fc$a)?($DATE$a)($VERB${l}mode:[^PNG]\|${r})/$3/g;

# CprepR: NOUNCOORD PRP NOUNCOORD
(@temp) = ($listTags =~ /($NOUNCOORD)($PRP$a)($NOUNCOORD)/g);
$Rel =  "CprepR";
HeadRelDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD)($PRP$a)($NOUNCOORD)/$1/g;

# SpecL: [VERB] CONJ<lemma:that|whether>  VERB<mode:[^PNG]>
# NEXT
# DobjComplR: VERB [CONJ<lemma:that|whether>] VERB<mode:[^PNG]>
(@temp) = ($listTags =~ /(?:$VERB$a)($CONJ${l}lemma:(?:that|whether)\|${r})($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$CONJ${l}lemma:(?:that|whether)\|${r})($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "DobjComplR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($CONJ${l}lemma:(?:that|whether)\|${r})($VERB${l}mode:[^PNG]\|${r})/$1/g;

# SpecL: [VERB]  CONJ<lemma:that|whether>  [NOUNCOORD|PRO<type:D|P|I|S>] VERB<mode:[^PNG]>
# NEXT
# SubjL:  [VERB]  [CONJ<lemma:that|whether>]  NOUNCOORD|PRO<type:D|P|I|S> VERB<mode:[^PNG]>
# NEXT
# DobjComplR: VERB   [CONJ<lemma:that|whether>] [NOUNCOORD|PRO<type:D|P|I|S>] VERB<mode:[^PNG]>
(@temp) = ($listTags =~ /(?:$VERB$a)($CONJ${l}lemma:(?:that|whether)\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "SpecL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$CONJ${l}lemma:(?:that|whether)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$CONJ${l}lemma:(?:that|whether)\|${r})(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "DobjComplR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($CONJ${l}lemma:(?:that|whether)\|${r})($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^PNG]\|${r})/$1/g;

# DobjComplR: VERB [NOUN]? VERB<compl:yes&mode:[^PNG]>
(@temp) = ($listTags =~ /($VERB$a)(?:$NOUN$a)?($VERB${l}compl:yes\|${b}mode:[^PNG]\|${r})/g);
$Rel =  "DobjComplR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($NOUN$a)?($VERB${l}compl:yes\|${b}mode:[^PNG]\|${r})/$1$2/g;

# DobjComplR: VERB<lemma:say|think> [NOUN]? VERB<mode:[^PNG]>
(@temp) = ($listTags =~ /($VERB${l}lemma:(?:say|think)\|${r})(?:$NOUN$a)?($VERB${l}mode:[^PNG]\|${r})/g);
$Rel =  "DobjComplR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB${l}lemma:(?:say|think)\|${r})($NOUN$a)?($VERB${l}mode:[^PNG]\|${r})/$1$2/g;

# PunctL: [NOUNCOORD|PRO<type:D|P|I|S>] Fc|Fpa VERB [Fc|Fpt]
# NEXT
# PunctR: [NOUNCOORD|PRO<type:D|P|I|S>] [Fc|Fpa] VERB Fc|Fpt
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|S> [Fc|Fpa] VERB [Fc|Fpt]
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a)($VERB$a)(?:$Fc$a|$Fpt$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a)($VERB$a)($Fc$a|$Fpt$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})(?:$Fc$a|$Fpa$a)($VERB$a)(?:$Fc$a|$Fpt$a)/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|S)\|${r})($Fc$a|$Fpa$a)($VERB$a)($Fc$a|$Fpt$a)/$1/g;

# AdjnL: [Fc] VERB<mode:P> [Fc] VERB
# NEXT
# PunctL: Fc [VERB<mode:P>] [Fc] VERB
# NEXT
# PunctL: [Fc] [VERB<mode:P>] Fc VERB
(@temp) = ($listTags =~ /(?:$Fc$a)($VERB${l}mode:P\|${r})(?:$Fc$a)($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($Fc$a)(?:$VERB${l}mode:P\|${r})(?:$Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$Fc$a)(?:$VERB${l}mode:P\|${r})($Fc$a)($VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($Fc$a)($VERB${l}mode:P\|${r})($Fc$a)($VERB$a)/$4/g;

# CoordL: VERB CONJ<coord:no&lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# CoordR: [VERB]  CONJ<coord:no&lemma:and|or|y|e|et|o|ou> VERB
# Add: coord:verb
# Inherit: mode, tense
(@temp) = ($listTags =~ /($VERB$a)($CONJ${l}coord:no\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($CONJ${l}coord:no\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($CONJ${l}coord:no\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$2/g;
Inherit("HeadDep","mode,tense",@temp);
Add("HeadDep","coord:verb",@temp);

# CoordL: VERB [Fc] [VERB] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# PunctL:  [VERB] Fc [VERB] [Fc] CONJ<lemma:and|or|y|e|et|o|ou> [VERB]
# Add: coord:verb
# Recursivity: 5
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)(?:$VERB$a)(?:$Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($VERB$a)($Fc$a)($CONJ${l}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3$4$5$6/g;
Add("DepHead","coord:verb",@temp);

# PunctL: [VERB] Fc CONJ<coord:verb&lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# CoordL: VERB [Fc] CONJ<coord:verb&lemma:and|or|y|e|et|o|ou> [VERB]
# NEXT
# CoordR:  [VERB] [Fc] CONJ<coord:verb&lemma:and|or|y|e|et|o|ou> VERB
# Add: coord:verb
# Inherit: mode, tense
(@temp) = ($listTags =~ /(?:$VERB$a)($Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($VERB$a)(?:$Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})(?:$VERB$a)/g);
$Rel =  "CoordL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$VERB$a)(?:$Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/g);
$Rel =  "CoordR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($VERB$a)($Fc$a)($CONJ${l}coord:verb\|${b}lemma:(?:and|or|y|e|et|o|ou)\|${r})($VERB$a)/$3/g;
Inherit("HeadDep","mode,tense",@temp);
Add("HeadDep","coord:verb",@temp);

# SubjL: [NOUNCOORD] NOMINAL|PRO<type:D|P|I|S>  VERB<mode:[^G]>|CONJ<coord:verb&mode:[^G]>
# NEXT
# AdjnR: NOUNCOORD [NOMINAL|PRO<type:D|P|I|S>]  VERB<mode:[^G]>|CONJ<coord:verb&mode:[^G]>
(@temp) = ($listTags =~ /(?:$NOUNCOORD)($NOMINAL|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD)(?:$NOMINAL|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD)($NOMINAL|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/$1/g;

# SubjL: NOUN<type:D|P|I|S> VERB<mode:[^G]>|CONJ<coord:verb&mode:[^G]>
# Add: subj:yes
(@temp) = ($listTags =~ /($NOUN${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOUN${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/$2/g;
Add("DepHead","subj:yes",@temp);

# SubjL: NOMINAL|PRO<type:D|P|I|S>  VERB<mode:[^G]>|CONJ<coord:verb&mode:[^G]>
# Add: subj:yes
(@temp) = ($listTags =~ /($NOMINAL|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
$listTags =~ s/($NOMINAL|$PRO${l}type:(?:D|P|I|S)\|${r})($VERB${l}mode:[^G]\|${r}|$CONJ${l}coord:verb\|${b}mode:[^G]\|${r})/$2/g;
Add("DepHead","subj:yes",@temp);

# PunctL: [NOUNCOORD|PRO<type:D|P|I|X>] Fc [PRO<type:R|W>] VERB<subj:yes>|CONJ<subj:yes&coord:verb>    [Fc]?
# NEXT
# PunctR: [NOUNCOORD|PRO<type:D|P|I|X>] [Fc] [PRO<type:R|W>] VERB<subj:yes>|CONJ<subj:yes&coord:verb>   Fc
# NEXT
# DobjL: [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]? PRO<type:R|W> VERB<subj:yes>|CONJ<subj:yes&coord:verb>    [Fc]?
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|X> [Fc]? [PRO<type:R|W>] VERB<subj:yes>|CONJ<subj:yes&coord:verb>    [Fc]?
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB${l}subj:yes\|${r}|$CONJ${l}subj:yes\|${b}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB${l}subj:yes\|${r}|$CONJ${l}subj:yes\|${b}coord:verb\|${r})($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?($PRO${l}type:(?:R|W)\|${r})($VERB${l}subj:yes\|${r}|$CONJ${l}subj:yes\|${b}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "DobjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?(?:$PRO${l}type:(?:R|W)\|${r})($VERB${l}subj:yes\|${r}|$CONJ${l}subj:yes\|${b}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?($PRO${l}type:(?:R|W)\|${r})($VERB${l}subj:yes\|${r}|$CONJ${l}subj:yes\|${b}coord:verb\|${r})($Fc$a)?/$1/g;

# PunctL: [NOUNCOORD|PRO<type:D|P|I|X>] Fc [PRO<type:R|W>] VERB|CONJ<coord:verb>   [Fc]?
# NEXT
# PunctR: [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]? [PRO<type:R|W>] VERB|CONJ<coord:verb> Fc
# NEXT
# SubjL: [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]? PRO<type:R|W> VERB|CONJ<coord:verb>   [Fc]?
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|X> [Fc]? [PRO<type:R|W>] VERB|CONJ<coord:verb>  [Fc]?
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "SubjL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})($Fc$a)?/$1/g;

# PunctL: [NOUNCOORD|PRO<type:D|P|I|X>] Fc [PRP] [PRO<type:R|W>] VERB|CONJ<coord:verb>   [Fc]?
# NEXT
# PunctR: [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]?  [PRP] [PRO<type:R|W>] VERB|CONJ<coord:verb> Fc
# NEXT
# CircL: [NOUNCOORD|PRO<type:D|P|I|X>] [Fc]? PRP PRO<type:R|W> VERB|CONJ<coord:verb>  [Fc]?
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|X> [Fc]? [PRP] [PRO<type:R|W>] VERB|CONJ<coord:verb>  [Fc]?
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)(?:$PRP$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?(?:$PRP$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})($Fc$a)/g);
$Rel =  "PunctR";
HeadDep($Rel,"",@temp);
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?($PRP$a)($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "CircL";
RelDepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?(?:$PRP$a)(?:$PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})(?:$Fc$a)?/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?($PRP$a)($PRO${l}type:(?:R|W)\|${r})($VERB$a|$CONJ${l}coord:verb\|${r})($Fc$a)?/$1/g;

# PunctL: [NOUNCOORD|PRO<type:D|P|I|X>] Fc VERB<mode:[GP]>|CONJ<coord:verb>
# NEXT
# AdjnR: NOUNCOORD|PRO<type:D|P|I|X> [Fc]? VERB<mode:[GP]>|CONJ<coord:verb>
(@temp) = ($listTags =~ /(?:$NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)($VERB${l}mode:[GP]\|${r}|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "PunctL";
DepHead($Rel,"",@temp);
(@temp) = ($listTags =~ /($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})(?:$Fc$a)?($VERB${l}mode:[GP]\|${r}|$CONJ${l}coord:verb\|${r})/g);
$Rel =  "AdjnR";
HeadDep($Rel,"",@temp);
$listTags =~ s/($NOUNCOORD|$PRO${l}type:(?:D|P|I|X)\|${r})($Fc$a)?($VERB${l}mode:[GP]\|${r}|$CONJ${l}coord:verb\|${r})/$1/g;

# AdjnL: CONJ<type:S> VERB
(@temp) = ($listTags =~ /($CONJ${l}type:S\|${r})($VERB$a)/g);
$Rel =  "AdjnL";
DepHead($Rel,"",@temp);
$listTags =~ s/($CONJ${l}type:S\|${r})($VERB$a)/$2/g;

############################## END GRAMMAR  ###############################

if ($ListInit eq $listTags) {
       $STOP = 1;
   }
  }
    #print STDERR "Iterations: $iteration\n";

#########SAIDA CORRECTOR TAGGER

   if ($flag eq "-c") {

       for  ($i=0;$i<=$#Token;$i++) {
          print "$Token[$i]\t";
          $OrdTags{"tag"} = $Tag[$i]; 
          foreach $feat (keys %{$ATTR[$i]}) {
              $OrdTags{$feat} = $ATTR[$i]{$feat};
	  }
          foreach $feat (sort keys %OrdTags) {
                 print "$feat:$OrdTags{$feat}|";
                 delete $OrdTags{$feat};
          }
       print "\n";
       ##Colocar a zero os vectores de cada ora�ao
       delete  $Token[$i];
       delete  $Tag[$i];
       delete  $Lemma[$i];
       delete  $Attributes[$i];
       delete  $ATTR[$i];
       }
       
    }
#########SAIDA STANDARD DO ANALISADOR 

    elsif ($flag eq "-a") {

      ##Escrever a ora�ao que vai ser analisada:
      print "SENT::\n";
      #print STDERR "LIST:: $listTags\n";
      ####imprimir Hash de dependencias ordenado:
      foreach $triplet (sort {$Ordenar{$a} <=>
                              $Ordenar{$b} }
                         keys %Ordenar ) {
         $triplet =~ s/^\(//;
         $triplet =~ s/\)$//;
         ($re, $he, $de) =  split (";", $triplet) ;
         if ($re !~ /($DepLex)/) {
           ($he ,$ta1, $pos1) = split ("_", $he);
            $he = $Lemma[$pos1];
            ($de ,$ta2, $pos2) = split ("_", $de);
            $de = $Lemma[$pos2];
            $triplet = "$re;$he\_$ta1\_$pos1;$de\_$ta2\_$pos2" ;
         }
         print "($triplet)\n";
       }
       ##final de analise de frase:
       print "---\n";
     }


  ###SAIDA ANALISADOR COM ESTRUTURA ATRIBUTO-VALOR (full analysis)
   elsif ($flag eq "-fa") {

      ##Escrever a ora�ao que vai ser analisada:
      print "SENT::$seq\n";
      #print STDERR "LIST:: $listTags\n";
      ####imprimir Hash de dependencias ordenado:
      $re="";
      foreach $triplet (sort {$Ordenar{$a} <=>
                              $Ordenar{$b} }
                         keys %Ordenar ) {
           # print "$triplet\n";
         $triplet =~ s/^\(//;
         $triplet =~ s/\)$//;
         ($re, $he, $de) =  split (";", $triplet) ;

         if ($re !~ /($DepLex)/) { ##se rel nao e lexical
           ($he1, $ta1, $pos1) = split ("_", $he);
            $he1 = $Lemma[$pos1];
            ($de2 ,$ta2, $pos2) = split ("_", $de);
            $de2 = $Lemma[$pos2];
            $triplet = "$re;$he1\_$ta1\_$pos1;$de2\_$ta2\_$pos2" ;
         }
         print "($triplet)\n";
         ($he, ,$ta, $pos) = split ("_", $he);
         print "HEAD::$he\_$ta\_$pos<";
         $ATTR[$pos]{"lemma"} = $Lemma[$pos];
         $ATTR[$pos]{"token"} = $Token[$pos];
         foreach $feat (sort keys %{$ATTR[$pos]}) {
           print "$feat:$ATTR[$pos]{$feat}|" ;
         }
         print ">\n";
         ($de, $ta, $pos) = split ("_", $de);
         print "DEP::$de\_$ta\_$pos<";
         $ATTR[$pos]{"lemma"} = $Lemma[$pos];
         $ATTR[$pos]{"token"} = $Token[$pos];
         foreach $feat (sort keys %{$ATTR[$pos]}) {
           print "$feat:$ATTR[$pos]{$feat}|" ;
         }
         print ">\n";

         if ($re =~ /\//) {
          ($depName, $reUnit) = split ('\/', $re);
          ($reLex, ,$ta, $pos) = split ("_", $reUnit);
          print "REL::$reLex\_$ta\_$pos<";
          $ATTR[$pos]{"lemma"} = $Lemma[$pos];
          $ATTR[$pos]{"token"} = $Token[$pos];
          foreach $feat (sort keys %{$ATTR[$pos]}) {
           print "$feat:$ATTR[$pos]{$feat}|" ;
          }
         print ">\n";
        }
      }
       ##final de analise de frase:
       print "---\n";
     }



      
      ##Colocar numa lista vazia os strings com os tags (listTags) e a ora�ao (seq)
      ##Borrar hash ordenado de triplets
      
      $i=0;
      $j=0;
      $listTags="";
      $seq="";
      foreach $t (keys %Ordenar) {
         delete  $Ordenar{$t};
      }
      for  ($i=0;$i<=$#Token;$i++) {
         delete  $Token[$i];
         delete  $Tag[$i];
         delete  $Lemma[$i];
         delete  $Attributes[$i];
         delete  $ATTR[$i];
       }
   
    

  } ##fim do elsif


 
 
 
    }
    
} 





##########################
####FUNCIONS DO PARSER####
##########################

sub HeadDep {

    my ($y,$z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

    for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);


           if ($z eq "") {
              $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
              $Rel =  $y ;
              $Dep =  "$Lemma[$n2]_$Tag[$n2]_${n2}" ;

              $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;

            }
            else {
             foreach $atr (@z) {
	
		if ( ($ATTR[$n1]{$atr} ne $ATTR[$n2]{$atr}) && 
                      ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n2]{$atr}  !~  /^[NC0]$/) && ##a modificar: so no caso de que atr = number or genre (N = invariable or neutral)
		     ($ATTR[$n1]{$atr} ne "" && $ATTR[$n2]{$atr} ne  "") ) {
                      
		       $found++;

                }
             }
	
	     # print STDERR "Found: $found\n";
              if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:1\|/;
               $found=0;


               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  $y ;
               $Dep =  "$Lemma[$n2]_$Tag[$n2]_${n2}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;
            }
	   }

    }


}


sub DepHead {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

   # print STDERR "-$y-, -$z-, -@x-\n";

    for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);

            if ($z eq "") {
              $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
              $Rel =  $y ;
              $Dep =  "$Lemma[$n2]_$Tag[$n2]_${n2}" ;

              $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;

            }
            else {
	     
              foreach $atr (@z) {
	      
                 if ( ($ATTR[$n1]{$atr} ne $ATTR[$n2]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n2]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n2]{$atr} ne  "") ) {
		       $found++ ;
                 }
	        
              }
	    
            #  print STDERR "Found: $found\n";
             if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:0\|/;
                $found=0;

             }
             else  {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:1\|/;
               $found=0;


               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  $y ;
               $Dep =  "$Lemma[$n2]_$Tag[$n2]_${n2}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;
	     }
          }

    }


}


sub DepRelHead {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $n3=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

     for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Rel = $x[$m];
            $m++;
            $Head = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Rel =~ /[\w]+_([0-9]+)/);
           ($n3) = ($Dep =~ /[\w]+_([0-9]+)/);

            if ($z eq "") {
               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

            }
            else {
             foreach $atr (@z) {
	
                if ( ($ATTR[$n1]{$atr} ne $ATTR[$n3]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n3]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n3]{$atr} ne  "") ) {
		       $found++ ;
                }
		
             }
	
             if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:1\|/;
               $found=0;


	       $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

             }
	   }

    }


}



sub HeadRelDep {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $n3=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

    for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Rel = $y . "_" . $x[$m];
            $m++;
            $Dep = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Rel =~ /[\w]+_([0-9]+)/);
           ($n3) = ($Dep =~ /[\w]+_([0-9]+)/);


             if ($z eq "") {
               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

                $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

            }
            else {
             foreach $atr (@z) {
	
                 if ( ($ATTR[$n1]{$atr} ne $ATTR[$n3]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n3]{$atr}  !~  /^[NC0]$/) && 
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n3]{$atr} ne  "") ) {
		       $found++ ;
                }
	

             }
	
             if ($found > 0)  {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:1\|/;
               $found=0;


               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

	     }
	   }


    }

}





sub RelDepHead {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $n3=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

     for ($m=0;$m<=$#x;$m++) {
            $Rel = $x[$m];
            $m++;
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Rel =~ /[\w]+_([0-9]+)/);
           ($n3) = ($Dep =~ /[\w]+_([0-9]+)/);

            if ($z eq "") {
               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

            }
            else {
             foreach $atr (@z) {
	
                if ( ($ATTR[$n1]{$atr} ne $ATTR[$n3]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n3]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n3]{$atr} ne  "") ) {
		       $found++ ;
                }
		
             }
	
             if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:1\|/;
               $found=0;


	       $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

             }
	   }

    }


}


sub RelHeadDep {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $n3=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

     for ($m=0;$m<=$#x;$m++) {
            $Rel = $x[$m];
            $m++;
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Rel =~ /[\w]+_([0-9]+)/);
           ($n3) = ($Dep =~ /[\w]+_([0-9]+)/);

            if ($z eq "") {
               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

            }
            else {
             foreach $atr (@z) {
	
                if ( ($ATTR[$n1]{$atr} ne $ATTR[$n3]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n3]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n3]{$atr} ne  "") ) {
		       $found++ ;
                }
		
             }
	
             if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:1\|/;
               $found=0;


	       $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

             }
	   }

    }


}


sub DepHeadRel {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $n3=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

     for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            $m++;
            $Rel = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Rel =~ /[\w]+_([0-9]+)/);
           ($n3) = ($Dep =~ /[\w]+_([0-9]+)/);

            if ($z eq "") {
               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

            }
            else {
             foreach $atr (@z) {
	
                if ( ($ATTR[$n1]{$atr} ne $ATTR[$n3]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n3]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n3]{$atr} ne  "") ) {
		       $found++ ;
                }
		
             }
	
             if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:1\|/;
               $found=0;


	       $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

             }
	   }

    }


}


sub HeadDepRel {

    my ($y, $z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $n3=0;
    my $found=0;
    my @z;

    (@z) = split (",", $z);

     for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Rel = $x[$m];
            $m++;
            $Rel = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Rel =~ /[\w]+_([0-9]+)/);
           ($n3) = ($Dep =~ /[\w]+_([0-9]+)/);

            if ($z eq "") {
               $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

            }
            else {
             foreach $atr (@z) {
	
                if ( ($ATTR[$n1]{$atr} ne $ATTR[$n3]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n3]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n3]{$atr} ne  "") ) {
		       $found++ ;
                }
		
             }
	
             if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n3]_${n3}_<)/$1concord:1\|/;
               $found=0;


	       $Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Rel =  "$y/$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$Lemma[$n3]_$Tag[$n3]_${n3}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n3 ;

             }
	   }

    }


}




sub HeadDep_lex {

    my ($y,$z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $found=0;
    my @z;


    (@z) = split (",", $z);

    for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);

           if ($z eq "") {
              #$Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
              $Head = "$ATTR[$n1]{\"lemma\"}_$Tag[$n1]_${n1}" ;
              $Rel =  $y ;
              #$Dep = "$Lemma[$n2]_$Tag[$n2]_${n2}" ;
              $Dep =  "$ATTR[$n2]{\"lemma\"}_$Tag[$n2]_${n2}" ;

              $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;
              #print STDERR "head::$Head -- dep:::$Dep\n";

	      if (!defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} = $ATTR[$n1]{"lemma"} . "\@$Lemma[$n2]" ;
                 # $ATTR_token{$n1} = $ATTR[$n1]{"token"} .  "\@$Token[$n2]";

                  $IDF{$n1}++;

	      }

              elsif (!defined $ATTR_lemma{$n1} && defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} = $ATTR[$n1]{"lemma"} .  "\@$ATTR_lemma{$n2}" ;
                  #$ATTR_token{$n1} = $ATTR[$n1]{"token"} .   "\@$ATTR_token{$n2}";

                  $IDF{$n1}++;

	      }
              elsif (defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} .=   "\@$Lemma[$n2]" ;
                  #$ATTR_token{$n1} .=   "\@$Token[$n2]";


	      }
              else {

                     $ATTR_lemma{$n1} .=    "\@$ATTR_lemma{$n2}" ;
                   #  $ATTR_token{$n1} .=    "\@$ATTR_token{$n2}" ;

		
             }

            #print STDERR "$n1::: $ATTR_lemma{$n1} -- $ATTR_token{$n1} \n";

            }
            else {
             foreach $atr (@z) {
	
		if ( ($ATTR[$n1]{$atr} ne $ATTR[$n2]{$atr}) && 
                       ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n2]{$atr}  !~  /^[NC0]$/) &&
		      ($ATTR[$n1]{$atr} ne "" && $ATTR[$n2]{$atr} ne  "") ) {
		       $found++;

                }
             }
	
	     # print STDERR "Found: $found\n";
              if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:1\|/;
               $found=0;

               #$Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Head = "$ATTR[$n1]{\"lemma\"}_$Tag[$n1]_${n1}" ;
               $Rel =  $y ;
               #$Dep = "$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$ATTR[$n2]{\"lemma\"}_$Tag[$n2]_${n2}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;


               if (!defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} = $ATTR[$n1]{"lemma"} . "\@$Lemma[$n2]" ;
                 # $ATTR_token{$n1} = $ATTR[$n1]{"token"} .  "\@$Token[$n2]";

                  $IDF{$n1}++;

	       }

               elsif (!defined $ATTR_lemma{$n1} && defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} = $ATTR[$n1]{"lemma"} .  "\@$ATTR_lemma{$n2}" ;
                 # $ATTR_token{$n1} = $ATTR[$n1]{"token"} .   "\@$ATTR_token{$n2}";

                  $IDF{$n1}++;

	       }
               elsif (defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} .=   "\@$Lemma[$n2]" ;
                 # $ATTR_token{$n1} .=   "\@$Token[$n2]";


	       }
               else {

                     $ATTR_lemma{$n1} .=    "\@$ATTR_lemma{$n2}" ;
                  #   $ATTR_token{$n1} .=    "\@$ATTR_token{$n2}" ;

		
              }


            }

	   }
           $Lemma[$n1] = $ATTR_lemma{$n1} ;
          # $Token[$n1] = $ATTR_token{$n1} ;

    }



}


sub DepHead_lex {

 my ($y,$z, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my $found=0;
    my @z;


    (@z) = split (",", $z);

    for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];

           ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
           ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);

           if ($z eq "") {
              #$Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
              $Head = "$ATTR[$n1]{\"lemma\"}_$Tag[$n1]_${n1}" ;
              $Rel =  $y ;
              #$Dep = "$Lemma[$n2]_$Tag[$n2]_${n2}" ;
              $Dep =  "$ATTR[$n2]{\"lemma\"}_$Tag[$n2]_${n2}" ;

              $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;

              #print STDERR "OKKKK: #$Dep - $n2#\n";
               if (!defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} = $ATTR[$n2]{"lemma"} . "\@$Lemma[$n1]" ;
           #       $ATTR_token{$n1} = $ATTR[$n2]{"token"} .  "\@$Token[$n1]";

                  $IDF{$n1}++;

	       }

               elsif (!defined $ATTR_lemma{$n1} && defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} =   "$ATTR_lemma{$n2}\@"  . $ATTR[$n1]{"lemma"}  ;
            #      $ATTR_token{$n1} =   "$ATTR_token{$n2}\@" .  $ATTR[$n1]{"token"};

                  $IDF{$n1}++;

	       }
               elsif (defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} .=   "$Lemma[$n2]\@" ;
             #     $ATTR_token{$n1} .=   "$Token[$n2]\@" ;

	       }
               else {
                     $ATTR_lemma{$n1} .=    "$ATTR_lemma{$n1}\@" ;
              #       $ATTR_token{$n1} .=    "$ATTR_token{$n1}\@" ;

              }

	
            }
            else {
             foreach $atr (@z) {
	
		if ( ($ATTR[$n1]{$atr} ne $ATTR[$n2]{$atr}) && 
                        ($ATTR[$n1]{$atr} !~  /^[NC0]$/ && $ATTR[$n2]{$atr}  !~  /^[NC0]$/) &&
                       ($ATTR[$n1]{$atr} ne "" && $ATTR[$n2]{$atr} ne  "")  ) {
		       $found++;

                }
             }
	
	     # print STDERR "Found: $found\n";
              if ($found > 0) {
               	$listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:0\|/;
                $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:0\|/;
                $found=0;
             }
             else {

               $listTags =~ s/($Tag[$n1]_${n1}_<)/$1concord:1\|/;
               $listTags =~ s/($Tag[$n2]_${n2}_<)/$1concord:1\|/;
               $found=0;

               #$Head = "$Lemma[$n1]_$Tag[$n1]_${n1}" ;
               $Head = "$ATTR[$n1]{\"lemma\"}_$Tag[$n1]_${n1}" ;
               $Rel =  $y ;
               #$Dep = "$Lemma[$n2]_$Tag[$n2]_${n2}" ;
               $Dep =  "$ATTR[$n2]{\"lemma\"}_$Tag[$n2]_${n2}" ;

               $Ordenar{"($Rel;$Head;$Dep)"} = $n2 ;

               if (!defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} = $ATTR[$n2]{"lemma"} . "\@$Lemma[$n1]" ;
               #   $ATTR_token{$n1} = $ATTR[$n2]{"token"} .  "\@$Token[$n1]";

                  $IDF{$n1}++;

	       }

                elsif (!defined $ATTR_lemma{$n1} && defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} =   "$ATTR_lemma{$n2}\@"  . $ATTR[$n1]{"lemma"}  ;
                #  $ATTR_token{$n1} =   "$ATTR_token{$n2}\@" .  $ATTR[$n1]{"token"};

                  $IDF{$n1}++;

	       }
               elsif (defined $ATTR_lemma{$n1} && !defined $ATTR_lemma{$n2} ) {
                  $ATTR_lemma{$n1} .=   "$Lemma[$n2]\@" ;
                 # $ATTR_token{$n1} .=   "$Token[$n2]\@" ;

	       }
               else {
                     $ATTR_lemma{$n1} .=    "$ATTR_lemma{$n1}\@" ;
                  #   $ATTR_token{$n1} .=    "$ATTR_token{$n1}\@" ;

              }

            }
	   }
           $Lemma[$n1] = $ATTR_lemma{$n1} ;
          # $Token[$n1] = $ATTR_token{$n1} ;

    }

}



sub Head {

    my ($y, $z, @x) = @_ ;

   return 1

}




sub LEX {
    my $idf=0 ;
    foreach $idf (keys %IDF) {
       #print STDERR "idf = $idf";

       ##parche para \2... \pi...:
      # $ATTR[$idf]{"lemma"}  =~ s/[\\]/\\\\/g ;
      # $ATTR[$idf]{"token"}  =~ s/[\\]/\\\\/g ;
       
       $listTags =~ s/($Tag[$idf]_${idf}${l})lemma:$ATTR[$idf]{"lemma"}/${1}lemma:$ATTR_lemma{$idf}/;
      # $listTags =~ s/($Tag[$idf]_${idf}${l})token:$ATTR[$idf]{"token"}/${1}token:$ATTR_token{$idf}/;

       delete $IDF{$idf};
       delete $ATTR_lemma{$idf};
       #delete $ATTR_token{$idf};


    }


}


##Opera�oes Corr, Inherit, Add, 

sub Corr {

    my ($z, $y, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my @y="";
    my $atr="";
    my $value="";
    my $info="";
    my $attribute="";
    my $entry="";

    (@y) = split (",", $y);


    if ($z eq "Head") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
            
               ##token:=lemma / lemma:=token
               if ($value =~ /^=/) {
		   $value =~ s/^=//;
                  $ATTR[$n1]{$atr} = $ATTR[$n1]{$value} ;
		   if ($value eq "token") {
                     $Lemma[$n1] = $ATTR[$n1]{$value} ;
		   }
                   elsif ($value eq "lemma") {
                     $Token[$n1] = $ATTR[$n1]{$value} ;
		   }
               } 
              

               ##change the PoS tag:
               elsif ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $entry = "${value}_${n1}_<";

                  if (activarTags($value,$n1)) {
                    
                   foreach $attribute (sort keys %{$ATTR[$n1]}) {
		        # print STDERR "--atribs: $attribute\n";      
		      if (defined $TagStr{$attribute}) {
                        $entry .= "$attribute:$ATTR[$n1]{$attribute}|" ;
                        #print STDERR "atribute defined : $attribute --$entry\n";
		      }
                      else {
			#$entry .= "$attribute:$TagStr{$attribute}|" ;
			  delete $ATTR[$n1]{$attribute} ;
                          #print STDERR "++entry : $entry\n";
		      } 
                     
                    }

                    foreach $attribute (sort keys %TagStr) {
		        # print STDERR "++atribs: $attribute\n";      
		      if (!defined $ATTR[$n1]{$attribute}) {
                        $entry .= "$attribute:$ATTR[$n1]{$attribute}|" ;
			$ATTR[$n1]{$attribute} = $TagStr{$attribute};
                        #print STDERR "++atribute defined : $attribute --$entry\n";
		      }
                      
                     
                    }
		  }

	          $entry .= ">";
                  #print STDERR  "--$entry\n" ;
                  $listTags =~ s/$Tag[$n1]_$n1$a/$entry/;
                  $Tag[$n1] = $value;
                  desactivarTags($value);
               }

	       elsif ($listTags =~ /$Tag[$n1]_${n1}${l}$atr/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
                
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};  

		 }
                
               }
	     }

      }
   }

 

}




sub Inherit {

    my ($z, $y, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my @y="";


    (@y) = split (",", $y);


    if ($z eq "DepHead") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
             foreach $atr (@y) {
		 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};
	     }

      }
   }

   elsif ($z eq "HeadDep") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
             foreach $atr (@y) {
                  if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};

	     }

      }
   }

   elsif ($z eq "DepRelHead") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m +=2;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
             foreach $atr (@y) {
                 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};

	     }

      }
   }

    elsif ($z eq "HeadRelDep") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m +=2;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
             foreach $atr (@y) {
                 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};

	     }

      }
   }

   elsif ($z eq "RelDepHead") {
      for ($m=0;$m<=$#x;$m++) {
	    $m++;
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
             foreach $atr (@y) {
                if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};
                 
	     }

      }
   }

   elsif ($z eq "RelHeadDep") {
      for ($m=0;$m<=$#x;$m++) {
	    $m++;
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
             foreach $atr (@y) {
                 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};

	     }

      }
   }


   elsif ($z eq "DepHeadRel") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
             foreach $atr (@y) {
                if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr};               
	     }

      }
   }

   elsif ($z eq "HeadDepRel") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
             foreach $atr (@y) {
                 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr}; 
                 
	     }

      }
   }

   elsif ($z eq "DepHead_lex") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
             foreach $atr (@y) {
                 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr}; 
                 
	     }

      }
   }

   elsif ($z eq "HeadDep_lex") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
             foreach $atr (@y) {
                 if (!$ATTR[$n1]{$atr}) {
                    $listTags =~ s/($Tag[$n1]_${n1}${l})/${1}$atr:$ATTR[$n2]{$atr}\|/;
                 }
                 else {
                  $listTags =~ s/($Tag[$n1]_${n1}${l})$atr:$ATTR[$n1]{$atr}/${1}$atr:$ATTR[$n2]{$atr}/;
		 }
                 $ATTR[$n1]{$atr} = $ATTR[$n2]{$atr}; 

	     }

      }
   }
}


sub Add {

    my ($z, $y, @x) = @_ ;
    my $n1=0;
    my $n2=0;
    my @y="";
    my $atr="";
    my $value="";
    my $info="";

    (@y) = split (",", $y);


 
  
  if ($z eq "Head") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            

            foreach $info (@y) {
               ($atr, $value) = split (":", $info) ;
                if ($listTags =~ /$Tag[$n1]_${n1}${l}$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
                  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
                  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
               }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
                 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
                 }
               }
             }



      }
   }

   elsif ($z eq "DepHead") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;

               ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                   $Tag[$n1] = $value;
               }
	       elsif ($listTags =~ /$Tag[$n1]_${n1}${l}$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
                 # print STDERR "$atr - $value : #$l# - #$r#";
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
                  #print STDERR "$atr - $value ::: #$l# - #$r#";
               }
	     }

      }
   }

   elsif ($z eq "HeadDep") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
	
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
               
                ##change the PoS tag:
                if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /$Tag[$n1]_${n1}${l}$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value; 
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
               }
	     }

	     

      }
   }

   elsif ($z eq "DepRelHead") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m+=2;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                ##change the PoS tag:
                if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                   $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /($Tag[$n1]_${n1}${l})$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
               }
	     }
      }
   }

    
    elsif ($z eq "HeadRelDep") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m +=2;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
	
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /($Tag[$n1]_${n1}${l})$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
               }
	     }

      }
   }


   elsif ($z eq "RelDepHead") {
      for ($m=0;$m<=$#x;$m++) {
            $m++;
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /($Tag[$n1]_${n1}${l})$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
               }
	     }
      }
   }


   elsif ($z eq "RelHeadDep") {
      for ($m=0;$m<=$#x;$m++) {
            $m++;
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                ##change the PoS tag:
                if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /($Tag[$n1]_${n1}${l})$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
               }
	     }
      }
   }


   elsif ($z eq "DepHeadRel") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
	       elsif ($listTags  =~ /($Tag[$n1]_${n1}${l})$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
               }
	     }
      }
   }


   elsif ($z eq "HeadDepRel") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                 ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /($Tag[$n1]_${n1}${l})$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                 if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		 }
                 if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		 }
               }
	     }
      }
   }



   elsif ($z eq "DepHead_lex") {
      for ($m=0;$m<=$#x;$m++) {
            $Dep = $x[$m];
            $m++;
            $Head = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
              
                ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
	       elsif ($listTags =~ /$Tag[$n1]_${n1}${l}$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}$info\|/;
	       }
               else {
                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                   if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
               }
	     }

      }
   } 

   if ($z eq "HeadDep_lex") {
      for ($m=0;$m<=$#x;$m++) {
            $Head = $x[$m];
            $m++;
            $Dep = $x[$m];
            ($n1) = ($Head =~ /[\w]+_([0-9]+)/) ;
            ($n2) = ($Dep =~ /[\w]+_([0-9]+)/);  
		
            foreach $info (@y) {
	       ($atr, $value) = split (":", $info) ;
	       
                ##change the PoS tag:
               if ($atr =~ /^tag/) {
                  $ATTR[$n1]{$atr} = $value;
                  $listTags =~ s/$Tag[$n1]/$value/;
                  $Tag[$n1] = $value;
               }
               elsif ($listTags =~ /$Tag[$n1]_${n1}${l}$atr:/) {
                  $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                  $listTags =~ s/($Tag[$n1]_${n1}${l})${atr}:[^|]*\|/${1}${info}\|/;
	       }
               else {

                 $listTags =~ s/($Tag[$n1]_${n1}_<)/${1}$info\|/;
                 $ATTR[$n1]{$atr} = $value;
                  if ($atr eq "lemma") {
                    $Lemma[$n1] = $ATTR[$n1]{"lemma"};
		  }
                  if ($atr eq "token") {
                    $Token[$n1] = $ATTR[$n1]{"token"};
		  }
                 #print STDERR "$atr - $value ::: #$l# - #$r#";
               }
	     }
        
      }
   } 


}



sub negL {

    my ($x) = @_ ;
    my $expr="";
    my $ref="";
    my $CAT="";
  
    ($CAT, $ref) = split ("_", $x);  
    $expr = "(?<!${CAT})\\_$ref";
  

   return $expr
}

sub negR {

    my ($x) = @_ ;
    my $expr="";
    my $ref="";
    my $CAT="";
 
    ($CAT, $ref) = split ("_", $x); 
    $expr = "?!${CAT}\\_$ref";
 
   return $expr
}



sub activarTags {

   my ($x, $pos) = @_ ; 

   ##shared attributes:
   # $TagStr{"tag"} = 0;
    $TagStr{"lemma"} = 0;
    $TagStr{"token"} = 0;
  
   if ($x =~ /^PRO/) {
  
      $TagStr{"type"} = 0;
      $TagStr{"person"} = 0;
      $TagStr{"gender"} = 0;
      $TagStr{"number"} = 0;
      $TagStr{"case"} = 0;
      $TagStr{"possessor"} = 0;
      $TagStr{"politeness"} = 0;
      $TagStr{"pos"} = $pos;
      return 1 ;
   }

     ##conjunctions:
    elsif ($x =~ /^C/) {
      
       $TagStr{"type"} =  0;
       $TagStr{"pos"} = $pos;
        return 1 ;
    }

    ##interjections:
    elsif ($x =~ /^I/) {
   
       $TagStr{"type"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
    }

   ##numbers
   elsif ($x =~  /^CARD/) {
       
       $TagStr{"number"} = "P";
       $TagStr{"person"} = 0;
       $TagStr{"gender"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
   }


    elsif ($x =~ /^ADJ/) {
       
       $TagStr{"type"} = 0;
       $TagStr{"degree"} = 0;
       $TagStr{"gender"} = 0;
       $TagStr{"number"} = 0;
       $TagStr{"function"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
   }


   elsif ($x =~ /^ADV/) {
       
       $TagStr{"type"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
   }


   elsif ($x =~ /^PRP/) {
       
       $TagStr{"type"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
   }


   elsif ($x =~ /^NOUN/) {
      
       $TagStr{"type"} = 0 ;
       $TagStr{"gender"} = 0;
       $TagStr{"number"} = 0;
       $TagStr{"person"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
   }

   elsif ($x =~ /^DT/) {
 
       $TagStr{"type"} = 0;
       $TagStr{"person"} = 0;
       $TagStr{"gender"} = 0;
       $TagStr{"number"} = 0;
       $TagStr{"possessor"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;
   }

  ##mudar tags nos verbos:
   elsif ($x =~ /^VERB/) {


       $TagStr{"type"} = 0;
       $TagStr{"mode"} = 0;
       $TagStr{"tense"} = 0;
       $TagStr{"person"} = 0;
       $TagStr{"number"} = 0;
       $TagStr{"gender"} = 0;
       $TagStr{"pos"} = $pos;
       return 1 ;  
   }
   else {
     return 0
   }

}


sub desactivarTags {

   my ($x) = @_ ; 

      delete $TagStr{"type"} ;
      delete $TagStr{"person"};
      delete $TagStr{"gender"} ;
      delete $TagStr{"number"} ;
      delete $TagStr{"case"} ;
      delete $TagStr{"possessor"} ;
      delete $TagStr{"politeness"} ;
      delete $TagStr{"mode"} ;
      delete $TagStr{"tense"} ;
      delete $TagStr{"function"} ;
      delete $TagStr{"degree"} ;
      delete $TagStr{"pos"} ;     
 
      delete $TagStr{"lemma"} ;
      delete $TagStr{"token"} ;
     # delete $TagStr{"tag"} ;
     return 1
}


sub ConvertChar {

    my ($x, $y) = @_ ;


    $info =~ s/lemma:$x/lemma:\*$y\*/g; 
    $info =~ s/token:$x/token:\*$y\*/g;

}

sub ReConvertChar {

    my ($x, $y, $z) = @_ ;

     $Attributes[$z] =~ s/lemma:\*$y\*/lemma:$x/g;
     $Attributes[$z] =~ s/token:\*$y\*/token:$x/g;
     $ATTR[$z]{"lemma"} =~ s/\*$y\*/$x/g;
     $ATTR[$z]{"token"} =~ s/\*$y\*/$x/g;
     $Token[$z] =~ s/\*$y\*/$x/g;
     $Lemma[$z] =~ s/\*$y\*/$x/g;

}
##############################
####FIN FUNCIONS DO PARSER####
##############################









