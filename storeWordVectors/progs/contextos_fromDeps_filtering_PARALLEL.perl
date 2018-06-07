#!/usr/bin/perl

use Parallel::ForkManager;
my $pm = Parallel::ForkManager->new(10);

#GERA OS CONTEXTOS, AS PALAVRAS E AS FREQUENCIAS USANDO UM FICHEIRO DE PALAVRAS FILTRADAS 
#lê o resultado do parsing: dependencias. 

#use progs::funcoes::categorias

$file = shift(@ARGV);
open (FILE, $file) or die "O ficheiro no pode ser aberto: $!\n";

while ($words = <FILE>) {
    chomp $words;
    $Words{$words}++;
    
}

our %NPN;
our %NPV;
our %VPN;
our %VPV;
our %APN;
our %APV;
our %NN;
our %NA;
our %AN;
our %RA;
our %VR;
our %RV;
our %VAmod;
our %VVmod;
our %VN;
our %NV;
our %DVV;
our %SVV;

while ($line = <STDIN>) {
    
    if ($line !~ /^SENT::/) {
        
        
        $rel="";
        $head="";
        $dep="";
        $cat_h="";
        $cat_d="";
        $cat_r="";
        
        chop($line);
        
        #tiramos as parenteses da dependencia
        $line =~ s/^\(//;
        $line =~ s/\)$//;
        # print STDERR "$line\n";
        
        $line =~ s/^(Circ|[iI]obj|Creg)/iobj/;
        
        ($rel, $head, $dep) = split('\;', $line);
        
        ($head,$cat_h) = split ("_", $head);
        ($dep,$cat_d) = split ("_", $dep);
        
        ##Filtering
        $w1 = $head . "_" . $cat_h;
        $w2 = $dep . "_" . $cat_d;
        #     print STDERR "w1 : #$w1# -- w2: #$w2#\n";
        #     if (!$Words{$w1} || !$Words{$w2}) 
        if (!$Words{$w1} && !$Words{$w2}) { 
            #	 print STDERR "w1 : #$w1# -- w2: #$w2#\n";
            next;
        }
        
        if ($rel =~ /_/) {
            ($rel, $cat_r) = split ("_", $rel);
            ($relname, $rel) = split ('\/', $rel);
            #print STDERR "REL::: $rel -- $cat_r\n";
        }
        
        
        
        
        
        ##REGRA  NOUN-PREP-NOUN 
        
        if ( ($cat_r =~ /^PRP|POS/) && ($cat_h =~ /^N/) && ($cat_d =~ /^N/) ){
            $NPN{$head,$rel,$dep}++;
        }
        
        ##REGRA  NOUN-PREP-VERB                                                                                                                                                        i   
        elsif ( ($cat_r =~ /^PRP|POS/) && ($cat_h =~ /^N/) && ($cat_d =~ /^V/) ){
            $NPV{$head,$rel,$dep}++;
        }
        
        
        ##REGRA  VERB-PREP-NOUN 
        
        elsif ( ($cat_r  =~ /^PRP/) && ($cat_h =~ /^V/) && ($cat_d =~ /^N/) ){
            $VPN{$head,$rel,$dep}++;
            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";
        }
        
        ##REGRA  VERB-PREP-VERB 
        elsif ( ($cat_r  =~ /^PRP/) && ($cat_h =~ /^V/) && ($cat_d =~ /^V/) ){
            $VPV{$head,$rel,$dep}++;
            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";                                                                                                               
        }
        
        
        ##REGRA  ADJ-PREP-NOUN                                                                                                                                                           
        elsif ( ($cat_r  =~ /^PRP/) && ($cat_h =~ /^ADJ/) && ($cat_d =~ /^N/) ){
            $APN{$head,$rel,$dep}++;
            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";                                                                                                               
        }
        ##REGRA  ADJ-PREP-VERB                                                                                                                                                           
        elsif ( ($cat_r  =~ /^PRP/) && ($cat_h =~ /^ADJ/) && ($cat_d =~ /^V/) ){
            $APV{$head,$rel,$dep}++;
            #  print STDERR "VERB-PRP-NOUN::: $head -- $rel -- dep\n";                                                                                                                                                                                                                                       
        }
        
        
        
        ##REGRA  NOUN-NOUN (linguas romances) 
        
        elsif ( ($rel eq "AdjnR") && ($cat_h =~ /^N/) && ($cat_d =~ /^N/) ){
            $NN{$head,$dep}++;
        }
        
        ##REGRA  NOUN-NOUN (ingles) 
        
        elsif ( ($rel eq "AdjnL") && ($cat_h =~ /^N/) && ($cat_d =~ /^N/) ){
            $NN{$head,$dep}++;
        }
        
        
        
        ##REGRAS NOUN-ADJ, ADJ-NOUN
        
        elsif ( ($rel eq "AdjnR") && ($cat_h =~ /^N/) && ($cat_d =~ /^ADJ/) ){
            $NA{$head,$dep}++;
        }
        
        elsif ( ($rel eq "AdjnL") && ($cat_h =~ /^N/) && ($cat_d =~ /^ADJ/) ){
            $AN{$head,$dep}++;
        }
        ##se o dependente e um cardinal, colocar a etiqueta para reduzir o numero de contextos diferentes
        elsif ( ($rel eq "AdjnL") && ($cat_h =~ /^N/) && ($cat_d =~ /^CARD/) ){
            $AN{$head,$cat_d}++;
        }
        
        
        ##REGRA  ADV-ADJ (Adjn)                                                                                                                              
        elsif ( ($rel =~ /^AdjnL/) && ($cat_h =~ /^ADJ/) && ($cat_d =~ /^ADV/) ){
            $RA{$head,$dep}++;
        }
        
        #REGRA  ADV-VERB (AdjnL)                                                                                                                              
        elsif ( ($rel =~ /^AdjnL/) && ($cat_h =~ /^VERB/) && ($cat_d =~ /^ADV/) ){
            $RV{$head,$dep}++;
        }
        #REGRA  VERB-ADV (AdjnR)                                                                                                                              
        elsif ( ($rel =~ /^AdjnR/) && ($cat_h =~ /^VERB/) && ($cat_d =~ /^ADV/) ){
            $VR{$head,$dep}++;
        }
        
        ##REGRA  VERB-ADJ (Atr)                                                                                                                              
        elsif ( ($rel =~ /^Atr/) && ($cat_h =~ /^V/) && ($cat_d =~ /^ADJ/) ){
            $VAmod{$head,$dep}++;
        }
        
        ##REGRA  VERB-VERB (Adjn)                                                                                                                              
        elsif ( ($rel =~ /^Adjn/) && ($cat_h =~ /^V/) && ($cat_d =~ /^V/) ){
            $VVmod{$head,$dep}++;
        }
        
        
        
        ##REGRA  VERB-NOUN
        
        elsif ( ($rel =~ /^(Dobj|Atr)/) && ($cat_h =~ /^V/) && ($cat_d =~ /^N/) ){
            $VN{$head,$dep}++;
        }
        
        ##participios com left object sao associados aos right objects...
        #     elsif ( ($rel =~ /^Subj/) && ($cat_h =~ /^VERBP/) && ($cat_d =~ /^N/) ){
        #          $VN{$head,$dep}++;
        #     }
        
        
        ##REGRA  NOUN-VERB
        
        elsif ( ($rel  =~ /^Subj/) && ($cat_h =~ /^V/) && ($cat_d =~ /^N/) ){
            $NV{$head,$dep}++;
        }
        
        ##REGRA  VERB-VERB (Dobj)                                                                                                                                   
        elsif ( ($rel =~ /^(Dobj|Atr)/) && ($cat_h =~ /^V/) && ($cat_d =~ /^V/) ){
            $DVV{$head,$dep}++;
        }
        ##REGRA  VERB-VERB (Subj)                                                                                                                                   
        elsif ( ($rel =~ /^Subj/) && ($cat_h =~ /^V/) && ($cat_d =~ /^V/) ){
            $SVV{$head,$dep}++;
        }
        
    }
    
}

my @refers = ('NPN', 'NPV', 'VPN', 'VPV', 'APN', 'APV', 'NN', 'NA', 'AN', 'RA', 'VR', 'RV', 'VAmod', 'VVmod', 'VN', 'NV', 'DVV', 'SVV');

no strict 'refs';
foreach my $hash (@refers){
     my $pid = $pm->start and next;
    # Como garadamos só as referencias, temos que recuperar o valor. Agora theHash equivale ao hash correcto. 
    my %theHash = %{$hash};
    
    open(my $fh, '>', "./frecuencias/frecuencia_$hash");
    
    foreach my $key (sort keys %theHash){
        my $valor = 0;
        
        if ( grep( /^$hash/, (('NPN', 'NPV', 'VPN', 'VPV', 'APN', 'APV') ) )) {
            ($p1, $p2, $p3) = split (/$;/o, $key);
            $valor = $theHash{$p1,$p2,$p3};
        }else{
            ($p1, $p2) = split (/$;/o, $key);
            $valor = $theHash{$p1,$p2};
        }
        
        
        if($valor > 0){
       
            if($hash eq 'NPN'){
                    printf $fh "Cprep&%s_down_%s %s %d\n", $p2, $p1, $p3 , $NPN{$p1,$p2,$p3};
                    #print STDERR "trigram: $p1-$p2-$p3\n";
                    printf $fh "Cprep&%s_up_%s %s %d\n", $p2, $p3, $p1, $NPN{$p1,$p2,$p3};
                }
                
                #NPV
                elsif($hash eq 'NPV'){
                    printf $fh "CprepV&%s_down_%s %s %d\n", $p2, $p1, $p3 , $NPV{$p1,$p2,$p3};
                    #print STDERR "trigram: $p1-$p2-$p3\n";                                                                                                        
                    printf $fh "CprepV&%s_up_%s %s %d\n", $p2, $p3, $p1, $NPV{$p1,$p2,$p3};
                }
                
                #VPN
                elsif($hash eq 'VPN'){
                    printf $fh "Iobj&%s_down_%s %s %d\n", $p2, $p1, $p3 , $VPN{$p1,$p2,$p3};
                    #print STDERR "trigram: $p1-$p2-$p3\n";                                                                                                       
                    printf $fh "Iobj&%s_up_%s %s %d\n", $p2, $p3, $p1, $VPN{$p1,$p2,$p3};
                }
                
                #VPV
                elsif($hash eq 'VPV'){
                    printf $fh "IobjV&%s_down_%s %s %d\n", $p2, $p1, $p3 , $VPV{$p1,$p2,$p3};
                    #print STDERR "trigram: $p1-$p2-$p3\n";                                                                                                       
                    printf $fh "IobjV&%s_up_%s %s %d\n", $p2, $p3, $p1, $VPV{$p1,$p2,$p3};
                }
                
                #APN
                elsif($hash eq 'APN'){
                    printf $fh "Aprep&%s_down_%s %s %d\n", $p2, $p1, $p3 , $APN{$p1,$p2,$p3};
                    #print STDERR "trigram: $p1-$p2-$p3\n";                                                                                                                                                                                                                                   
                    printf $fh "Aprep&%s_up_%s %s %d\n", $p2, $p3, $p1, $APN{$p1,$p2,$p3};
                }
                
                #APV
                elsif($hash eq 'APV'){
                    printf $fh "AprepV&%s_down_%s %s %d\n", $p2, $p1, $p3 , $APV{$p1,$p2,$p3};
                    #print STDERR "trigram: $p1-$p2-$p3\n"; 
                    printf $fh "AprepV&%s_up_%s %s %d\n", $p2, $p3, $p1, $APV{$p1,$p2,$p3};
                }
                
                #NN
                elsif($hash eq 'NN'){
                    printf $fh "modN_down_%s %s %d\n", $p1, $p2, $NN{$p1,$p2} ;
                    # print STDERR "bigram: $p1-modN-$p2\n";
                    printf $fh "modN_up_%s %s %d\n", $p2, $p1, $NN{$p1,$p2} ;
                }
                
                #NA
                elsif($hash eq 'NA'){
                    printf $fh "Rmod_down_%s %s %d\n", $p1, $p2, $NA{$p1,$p2} ;
                    #print STDERR "bigram: $p1-$p2\n";
                    printf $fh "Rmod_up_%s %s %d\n", $p2, $p1, $NA{$p1,$p2} ;
                }
                
                #AN
                elsif($hash eq 'AN'){
                    printf $fh "Lmod_down_%s %s %d\n", $p1, $p2, $AN{$p1,$p2} ;
                    #print STDERR "bigram: $p1-$p2\n";
                    printf $fh "Lmod_up_%s %s %d\n", $p2, $p1, $AN{$p1,$p2} ;
                }
                
                #RA
                elsif($hash eq 'RA'){
                    printf $fh "LmodA_down_%s %s %d\n", $p1, $p2, $RA{$p1,$p2} ;
                    #print STDERR "bigram: $p1-$p2\n";                                                                                                             
                    printf $fh "LmodA_up_%s %s %d\n", $p2, $p1, $RA{$p1,$p2} ;
                }
                
                #VR
                elsif($hash eq 'VR'){
                    printf $fh "RmodV_down_%s %s %d\n", $p1, $p2, $VR{$p1,$p2} ;
                    printf $fh "RmodV_up_%s %s %d\n", $p2, $p1, $VR{$p1,$p2} ;
                }
                
                #RV
                elsif($hash eq 'RV'){
                    printf $fh "LmodV_down_%s %s %d\n", $p1, $p2, $RV{$p1,$p2} ;
                    printf $fh "LmodV_up_%s %s %d\n", $p2, $p1, $RV{$p1,$p2} ;
                }
                
                #VAmod
                elsif($hash eq 'VAmod'){
                    printf $fh "Vmod_down_%s %s %d\n", $p1, $p2, $VAmod{$p1,$p2} ;
                    printf $fh "Vmod_up_%s %s %d\n", $p2, $p1, $VAmod{$p1,$p2} ;
                }
                
                #VVmod
                elsif($hash eq 'VVmod'){
                    printf $fh "VmodV_down_%s %s %d\n", $p1, $p2, $VVmod{$p1,$p2} ;
                    printf $fh "VmodV_up_%s %s %d\n", $p2, $p1, $VVmod{$p1,$p2} ;
                }
                
                #VN
                elsif($hash eq 'VN'){
                    printf $fh "Dobj_down_%s %s %d\n", $p1, $p2,  $VN{$p1,$p2} ;
                    #print STDERR "bigram: $p1-$p2\n";
                    printf $fh "Dobj_up_%s %s %d\n", $p2, $p1, $VN{$p1,$p2} ;
                }
                
                #NV
                elsif($hash eq 'NV'){
                    printf $fh "Subj_down_%s %s %d\n", $p1, $p2, $NV{$p1,$p2} ;
                    # print STDERR "bigram: $p1-$p2\n";
                    printf $fh "Subj_up_%s %s %d\n", $p2, $p1, $NV{$p1,$p2};
                }
                
                #DVV
                elsif($hash eq 'DVV'){
                    printf $fh "DobjV_down_%s %s %d\n", $p1, $p2,  $DVV{$p1,$p2} ;
                    #print STDERR "bigram: $p1-$p2\n";
                    printf $fh "DobjV_up_%s %s %d\n", $p2, $p1, $DVV{$p1,$p2} ;
                }
                
                #SVV
                elsif($hash eq 'SVV'){
                    printf $fh "SubjV_down_%s %s %d\n", $p1, $p2,  $SVV{$p1,$p2} ;
                    #print STDERR "bigram: $p1-$p2\n";
                    printf $fh "SubjV_up_%s %s %d\n", $p2, $p1, $SVV{$p1,$p2} ;
                }
        }
    }    
    close $fh;
    $pm->finish;
}

$pm->wait_all_children;




