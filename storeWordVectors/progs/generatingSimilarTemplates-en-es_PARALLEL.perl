#!/usr/bin/perl

use threads;
# LE UM FICHEIRO: O DXI DO OPENTRAD. DEVOLVE UMA LISTA DE TEMPLATES POTENCIAIS USANDO REGRAS ESPECIFICAS PARA OS NOMES DE DUAS LINGUAS: INGLES - PORTUGUES. 


#lê o ficheiro dxi em xml: <i> <l><r> ... (pipe)

#open (INPUT, $file) or die "O ficheiro não pode ser aberto: $!\n";
#use strict;
#use locale;
#use POSIX;
#use lib "/home/gamallo/BilingualExtraction/progs/funcoes" ;
#use funcoesBasicas
 
#setlocale(LC_CTYPE,"es_ES");

my constant $CORE_COUNT = 4;

for (1..$CORE_COUNT){
    threads->create(sub {
    $file = "temporal_ivan_".threads->tid();
    open ($fich, ">".$file) or die "O ficheiro temporal non pode ser creado: $!\n";
    
        while ($line = <STDIN>) {
            chop($line);
            my $pal1;
            my $pal2;
            ($tmp1, $tmp2, $tag) = split (" ", $line);
            $pal1 = lc ($tmp1);
            $pal2 = lc ($tmp2);
                
            # print STDERR  "##$pal1##, ##$pal2##, ##$tag##\n";
            $count++;  
            
            ##regras para NOUNS em ingles-portugues
            if ( ($pal1 ne "") && ($pal2 ne "") ) {
            
            if ($tag =~  /^N/ ){

            ##contextos nominais:

            printf $fich "modN_down_%s Cprep\&de_down_%s\n", $pal1, $pal2; 
            printf $fich "modN_up_%s Cprep\&de_up_%s\n", $pal1, $pal2; 

            printf $fich "Cprep\&of_down_%s Cprep\&de_down_%s\n", $pal1, $pal2;
            printf $fich "Cprep\&of_up_%s Cprep\&de_up_%s\n", $pal1, $pal2;

            printf $fich "modN_down_%s Cprep\&de_down_%s\n", $pal1, $pal2;
            printf $fich "modN_up_%s Cprep\&de_up_%s\n", $pal1, $pal2;

            preps ("Cprep", "down", $pal1, $pal2, $fich);
            preps ("Cprep", "up", $pal1, $pal2, $fich);

            
            ##contextos adjectivais:
            printf $fich "Lmod_down_%s Lmod_down_%s\n", $pal1, $pal2;
            printf $fich "Lmod_down_%s Rmod_down_%s\n", $pal1, $pal2;
            preps ("Aprep", "up", $pal1, $pal2, $fich);

            ##contextos verbais:
            printf $fich "Subj_up_%s Subj_up_%s\n", $pal1, $pal2;

            printf $fich "Dobj_up_%s Dobj_up_%s\n", $pal1, $pal2;

            preps ("Iobj", "up", $pal1, $pal2, $fich);
            
            }

            ##regras para ADJS em espanhol-galego
            elsif ($tag =~ /^ADJ/)  {


            ##contextos adjectivais:

            printf $fich "Lmod_up_%s Lmod_up_%s\n", $pal1, $pal2;
            printf $fich "Lmod_up_%s Rmod_up_%s\n", $pal1, $pal2;

            printf $fich "LmodA_down_%s LmodA_down_%s\n", $pal1, $pal2;
            printf $fich "Vmod_up_%s Vmod_up_%s\n", $pal1, $pal2;
            
            preps ("Aprep", "down", $pal1, $pal2, $fich);
            preps ("AprepV", "down", $pal1, $pal2, $fich);
            
            }

            

            ##contextos verbais:
            elsif ($tag =~ /^V/) {
            printf $fich "Subj_down_%s Subj_down_%s\n", $pal1, $pal2;
            printf $fich "Dobj_down_%s Dobj_down_%s\n", $pal1, $pal2;
            printf $fich "SubjV_down_%s SubjV_down_%s\n", $pal1, $pal2;
            printf $fich "SubjV_up_%s SubjV_up_%s\n", $pal1, $pal2;
            printf $fich "DobjV_down_%s DobjV_down_%s\n", $pal1, $pal2;
            printf $fich "DobjV_up_%s DobjV_up_%s\n", $pal1, $pal2;
            printf $fich "Vmod_down_%s Vmod_down_%s\n", $pal1, $pal2;
            printf $fich "RmodV_down_%s RmodV_down_%s\n", $pal1, $pal2;
            printf $fich "LmodV_down_%s RmodV_down_%s\n", $pal1, $pal2; #immediatly came - vino inmediatamente
            printf $fich "VmodV_down_%s VmodV_down_%s\n", $pal1, $pal2;
            printf $fich "VmodV_up_%s VmodV_up_%s\n", $pal1, $pal2;

            preps ("Iobj", "down", $pal1, $pal2, $fich);
            preps ("IobjV", "down", $pal1, $pal2, $fich);
            preps ("IobjV", "up", $pal1, $pal2, $fich);
            
            }

            ##contextos adverbais:
            elsif ($tag =~ /^ADV/) {
            printf $fich "LmodA_up_%s LmodA_up_%s\n", $pal1, $pal2;     
            printf $fich "RmodV_up_%s RmodV_up_%s\n", $pal1, $pal2;
            printf $fich "LmodV_up_%s RmodV_up_%s\n", $pal1, $pal2; #immediatly came - vino inmediatamente
        }
        }
        
        }
        
        close $fich;
    
    });
}

my $running_threads = $CORE_COUNT;
while ($running_threads) {
    for my $thread (threads->list(threads::joinable)) {
        $thread->join();
        $running_threads--;
    }

    sleep 1;
}

print STDERR "(palabras do dico) ficheiro gerado\n";


sub preps {
    my ($r) = $_[0];
    my ($d) = $_[1];
    my ($p1) = $_[2];
    my ($p2) = $_[3];
    my $fich = $_[4];

      printf $fich "$r\&from_$d\_%s $r\&de_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&from_$d\_%s $r\&desde_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&since_$d\_%s $r\&desde_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&about_$d\_%s $r\&de_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&with_$d\_%s $r\&con_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&in_$d\_%s $r\&en_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&into_$d\_%s $r\&en_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&at_$d\_%s $r\&en_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&for_$d\_%s $r\&para_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&for_$d\_%s $r\&durante_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&to_$d\_%s $r\&a_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&to_$d\_%s $r\&hasta_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&by_$d\_%s $r\&por_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&through_$d\_%s $r\&por_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&between_$d\_%s $r\&entre_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&on_$d\_%s $r\&sobre_$d\_%s\n", $p1, $p2;
      printf $fich "$r\&upon_$d\_%s $r\&sobre_$d\_%s\n", $p1, $p2;
      
   return 1
}


sub UpperToLower {
    local ($l) = @_;
     $l =~tr/A-Z/a-z/;
     $l =~tr/Ñ/ñ/;
     $l =~tr/\301\311\315\323\332\307\303\325\302\312\324\300\310/\341\351\355\363\372\347\343\365\342\352\364\340\350/;
     return $l;
}


