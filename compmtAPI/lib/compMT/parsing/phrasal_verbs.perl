#!/usr/bin/perl

##construi os candidatos a partir da frase-input e do dico bilingue
#input e output: comp, head, dep, rel

###partir dumha phrase Lobj,drive,coach&Robj,drive,coach
##cat_root:N, V..., cat_dep:N,V...
##ficheiro com as traduçoes do root composto (o target.txt anterior)

my $file = shift(@ARGV);
open (FILE, $file) or die "O ficheiro n o pode ser aberto: $!\n";



while (my $line = <FILE>) {
 chomp $line;
 my ($source, $target, $cat) = split ('\t', $line);
 $source = trim ($source);
 $target = trim ($target);
 #print STDERR "#$source# -- TARGET: #$target# --#$head# -- #$cat_h#\n";
 if ($source =~ /@/ && $cat =~ /^V/) { 
   $Comp{$source}++ 
 }

}

$i=0;
while (my $line = <STDIN>) {
 chomp $line;
 my ($token, $feat) = split ('\t', $line);

 ($lemma) = $feat =~ /lemma:([^\|]+)/;
 ($token) = $feat =~ /token:([^\|]+)/;
 ($cat) = $feat =~ /tag:([^\|]+)/;
 # print STDERR "lemma: #$lemma\n";
 $Token[$i] = $token;
 $Lemma[$i] = $lemma;
 $Cat[$i] = $cat;
 $Feat[$i] = $feat;
 $i++;
}

for ($i=0;$i<=$#Token;$i++) {

    $j= $i+1;
    $k= $i+2;
    $POS= $i;
    $Found=0;

    if ($Cat[$i] =~ /^V/ && $Cat[$j] =~ /^(PRP|PCLE|CS|ADV)/ && $Cat[$k] =~ /^(PRP|PCLE|CS|ADV)/){    # if ($Cat[$i] =~ /^V/ && $Cat[$j] =~ /^(PRP|PCLE)/ && $Cat[$k] =~ /^(PRP|PCLE)/) { CHANGE {
      $token = $Token[$i] . "@" . $Token[$j] . "@" .   $Token[$k];
      $lemma = $Lemma[$i] . "@" . $Lemma[$j] . "@" .   $Lemma[$k];
      if ($Comp{$lemma}) {
        $Feat[$i] =~ s/lemma:[^|]+\|/lemma:$lemma\|/;
        $Token[$i] = $token;
        $Lemma[$i] = $lemma;
       # print STDERR "lemma1: #$lemma# -- feat:  $Feat[$i] -- i: #$i#\n";
        $i += 2;
      }
      
    }
    if ($Cat[$i] =~ /^V/ && $Cat[$j] =~ /^(PRP|PCLE|CS|ADV)/ && !$Found) {     #  elsif ($Cat[$i] =~ /^V/ && $Cat[$j] =~ /^(PRP|PCLE)/) { CHANGE
      $token = $Token[$i] . "@" . $Token[$j];
      $lemma = $Lemma[$i] . "@" . $Lemma[$j] ;
      if ($Comp{$lemma}) {
       $Feat[$i] =~ s/lemma:[^|]+\|/lemma:$lemma\|/;
       $Token[$i] = $token;
       $Lemma[$i] = $lemma;
       #print STDERR "lemma2: #$lemma# -- feat:  $Feat[$i] -- i: #$i#\n";
       $i++;
      }
      
    }
    print "$Token[$POS]\t$Feat[$POS]\n";
}

sub trim {    #remove all leading and trailing spaces
  my ($str) = @_[0];

  $str =~ s/^\s*(.*\S)\s*$/$1/;
  return $str;
}

sub trad {   #traduz preposiçoes en-es
  my ($r) = @_[0];
  if ($r eq "of#E") {
      $result[0] = "de#S";
  }
  elsif ($r eq "from#E") {
      $result[0] = "de#S";
      $result[1] = "desde#S";
  }
  elsif ($r eq "with#E") {
      $result[0] = "con#S";
  }
  elsif ($r eq "by#E") {
      $result[0] = "por#S";
  }
  elsif ($r eq "for#E") {
      $result[0] = "para#S";
  }  
  elsif ($r eq "about#E") {
      $result[0] = "sobre#S";
  }
 elsif ($r eq "in#E") {
      $result[0] = "en#S";
  }
  elsif ($r eq "at#E") {
      $result[0] = "en#S";
      $result[1] = "a#S";
  }
  elsif ($r eq "to#E") {
      $result[0] = "a#S";
  }
  elsif ($r eq "on#E") {
      $result[0] = "sobre#S";
      $result[1] = "en#S";
  }
  return @result;
}
