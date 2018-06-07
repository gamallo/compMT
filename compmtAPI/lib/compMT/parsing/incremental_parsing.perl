#!/usr/bin/perl

$ling="#E";
while (my $dependency = <STDIN>) {
    chomp $dependency;
    if ($dependency !~ /\(/) {next}
    $dependency =~ s/^\(([^\)]+)\)$/$1/;
    my ($rel, $h, $d) = split (";", $dependency);
    if ($rel =~ /(Subj|Dobj|Lobj|Robj|iobj|Iobj|_|Lmod|Rmod|modN)/) {
        #$rel =~ s/bj[LR]/bj/g;
      
	#$Triples{$dependency}++;
        my ($head, $cat_h, $pos_h) = split ("_", $h);
        my ($dep, $cat_d, $pos_d) = split ("_", $d);
        if ($rel =~ /_/) {
           ($rel, $cat_r, $pos_r) = split ("_", $rel);
            $rel = $rel . $ling;
	   $rel = $rel . "_" . $cat_r . "_" . $pos_r;
	}
           
        $head = $head . $ling;
        $dep = $dep . $ling;
        $head = $head . "_" . $cat_h . "_" . $pos_h;
        $dep = $dep . "_" . $cat_d . "_" . $pos_d;
        

 ###cambio de rel names:
       if ($rel =~ /Lmod/ && $cat_d eq "NOUN") {
	    $rel = "modN";
        }
	elsif ($rel =~ /Lmod|Rmod/ && $cat_d ne "ADJ") {next}
#        elsif ($rel =~ /Subj|Lobj|Dobj|Robj/ && $cat_d ne "NOUN") {next}

	if ($rel =~ /Subj|Dobj|iobj|Iobj|Circ/ && $cat_d eq "VERB") {
            $rel =~ s/(Subj|Dobj|iobj|Iobj|Circ)/$1V/;
        }
        print STDERR "REL::: #$rel#\n";
        $Pos{$pos_h,$pos_d} = "$rel;$head;$dep" ;
        #$Pos{$pos_h} = $dependency;
        $Head{$pos_h} = $head;
        $Dep{$pos_d} = $dep;
        #print STDERR "DEP: #$dependency\n";
    }
}

my $previous = "";
foreach my $index (sort keys %Pos ) {
    my ($pos_h, $pos_d) = split (/$;/o, $index);
    
    my $current = $Pos{$pos_h, $pos_d};
    
    print STDERR scalar keys %Pos ; print STDERR  " $current ::  #$pos_d# #$pos_d_prev# \n";

    if (scalar keys %Pos == 1)  { #imprimimos o primeiro so numa linha
      print "($current)\n";
    }
    elsif (!$previous)  {
        print "($current)\n";
    }

    elsif ( ( ($Head{$pos_h_prev} eq $Head{$pos_h}) ||  ($Head{$pos_h_prev} eq $Dep{$pos_d}) ||
             ($Dep{$pos_d_prev} eq $Dep{$pos_d}) ||  ($Dep{$pos_d_prev} eq $Head{$pos_h}) ) && ($previous ne $current) ){
             print "($previous)&($current)\n";
    }

    $previous = $current;
    $pos_d_prev = $pos_d ;
    $pos_h_prev = $pos_h ;
}
