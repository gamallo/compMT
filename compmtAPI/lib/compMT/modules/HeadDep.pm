package HeadDep;
use Exporter;
use Time::HiRes qw( time );
use Clone 'clone';

our @ISA = qw( Exporter );

# these CAN be exported.
#our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(tHead tDep sHead sDep);

sub tHead {
    my @target = split( "\n", shift(@_) );
    my @tHead  = split( "\n", shift(@_) );

    my $Dico = shift(@_);
    my $Trad = shift(@_);
    my $Cntx = shift(@_);

    my $res   = "";
    my $resFr = "";

    my $th = 50;

    my $sep  = "&";
    my $ling = "S";

    my $dep;
    my $head;
    my $rel;
    my $rel_orig;
    my $dep_orig;
    my $head_orig;
    my $root;
    my $incr_d;
    my $incr_h;    ##incremental
    my $cat_h;
    my $pos_h;
    my $cat_d;
    my $pos_d;
    my $cat_r;
    my $pos_r;

    my %DicoA;
    my %incrTrad = ();
    my %incrDico = ();
    my %incrCntx = ();

    my $iterCounter = 0;
    my $frCounter = 0;
    my $otherCounter = 0;

    while ( my $line = shift(@tHead) )
    { ##percorremos o vector incremental, que esta vazio se começamos a processar a frase!
        chomp $line;
        my ( $cntx_bil, $word, $freq ) = split( " ", $line );

        $word =~ s/([^&]+)&//;
        $incrDico{$word}{$cntx_bil} = $freq;

        my ( $cntx1, $cntx2 ) = split( ";", $cntx_bil );
        $incrTrad{$cntx1}{$cntx2} = ${$Trad}{$cntx1}{$cntx2} + 1;
        $incrCntx{$cntx_bil}{$word} = $freq;
    }

    while ( my $phrase = shift(@target) ) {
        chomp $phrase;

        if ( $phrase !~ /$sep/ ) {
            $phrase =~ s/^\(([^\)]+)\)$/$1/;    ##borrar parenteses da analise
            ( $rel_orig, $head_orig, $dep_orig ) = split( ";", $phrase );
            ( $head,     $cat_h,     $pos_h )    = split( "_", $head_orig );
            ( $dep,      $cat_d,     $pos_d )    = split( "_", $dep_orig );
            ( $rel,      $cat_r,     $pos_r )    = split( "_", $rel_orig );
        }
        else {
            my @phr  = split( $sep, $phrase );
            my $last = $#phr;
            my $prev = $#phr - 1;
            $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
            $phr[$prev] =~ s/^\(([^\)]+)\)$/$1/;
            ( $rel_orig, $h1, $d1 ) = split( ";", $phr[$last] );
            ( $r2,       $h2, $d2 ) = split( ";", $phr[$prev] );
            if ( $h1 eq $h2 ) {
                $incr_h = 1;

                $head = $phrase;
                my $regex_head = quotemeta($phr[$last]);
                $head =~ s/&\($regex_head\)$//;

                ( $root, $cat_h, $pos_h ) = split( "_", $h1 );
                ( $dep,  $cat_d, $pos_d ) = split( "_", $d1 );
                ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
            }
            elsif ( $d1 eq $d2 || $d1 eq $h2 || $h1 eq $d2 ) {
                $incr_d = 1;

                $dep = $phrase;
                my $regex_dep = quotemeta($phr[$last]);
                $dep =~ s/&\($regex_dep\)$//;

                ( $head, $cat_h, $pos_h ) = split( "_", $h1 );
                ( $root, $cat_d, $pos_d ) = split( "_", $d1 );
                ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
            }
            else {
                die("No incrementality. Stop\n");
            }

        }

        my $freq = 1;
        my %found;
        my $c1       = "";
        my $cntx_dep = "";

        $rel = removeLing( $rel, $ling );

        if ( $incr_h || $phrase !~ /$sep/ ) {
            $c1 = $rel . "_up_" . $dep;
        }
        elsif ( $incr_d && $phrase =~ /$sep/ ) {
            $c1 = $rel . "_up_" . $root;
        }


        foreach my $c2 ( keys %{{%{${$Trad}{$c1}}, %{$incrTrad{$c1}}}} )
        {    #buscamos as traduçoes do contexto do adjectivo
            $frCounter++;
            $cntx_dep = $c2 . ";" . $c1;
            my $count = 0;

            if(exists($incrDico{$head}{$cntx_dep})) {
                $resFr .= "$c1 $head $incrDico{$head}{$cntx_dep}\n";
            } elsif(exists(${$Dico}{$head}{$cntx_dep})) {
                $resFr .= "$c1 $head ${$Dico}{$head}{$cntx_dep}\n";
            }

            if(exists($incrDico{$root}{$cntx_dep})) {
                $resFr .= "$c1 $head $incrDico{$root}{$cntx_dep}\n";
            } elsif(exists(${$Dico}{$root}{$cntx_dep})) {
                $resFr .= "$c1 $head ${$Dico}{$root}{$cntx_dep}\n";
            }

            my $temp = clone(${$Cntx}{$cntx_dep});
            @{$temp}{keys %{$incrCntx{$cntx_dep}}} = values %{$incrCntx{$cntx_dep}};

            foreach my $wordA (
                    sort { ${$temp}{$b} <=> ${$temp}{$a}  } keys %{$temp}
                )
            { ##conjunto de nomes modificados polo adjectivo na dependencia Lmod_up_adj
                if ( $count <= $th ) {
                    if ( $wordA eq $head || $wordA eq $root ) { next }
                    $count++;

                    foreach my $cntxA  ( keys %{{%{${$Dico}{$wordA}}, %{$incrDico{$wordA}}}} )
                    { ##aqui construimos o conjunto de contextos dos nomes associados ao adjectivo
                        if(exists($incrDico{$wordA}{$cntxA})) {
                            $DicoA{$phrase}{$cntxA} += $incrDico{$wordA}{$cntxA};
                        } elsif(exists(${$Dico}{$wordA}{$cntxA})) {
                            $DicoA{$phrase}{$cntxA} += ${$Dico}{$wordA}{$cntxA};
                        }
                    }
                }
            }
        }

        foreach my $cntxN ( keys %{{%{${$Dico}{$head} }, %{$incrDico{$head}}}})
        {    ##percorremos o conjunto de contextos do nome (nome = HEAD)
            $otherCounter = $otherCounter + 1;

            if(exists($incrDico{$head}{$cntxN})) {
                $freq = $DicoA{$phrase}{$cntxN} * $incrDico{$head}{$cntxN};
            } elsif(exists(${$Dico}{$head}{$cntxN})) {
                $freq = $DicoA{$phrase}{$cntxN} * ${$Dico}{$head}{$cntxN};
            }

            $res .= "$cntxN ($phrase) $freq\n"
                if ( $freq > 0 && $phrase !~ /$sep/ );

            my $root_h_full = $root . "_" . $cat_h . "_" . $pos_h
                if ( $phrase =~ /$sep/ && $incr_h );
            my $root_d_full = $root . "_" . $cat_d . "_" . $pos_d
                if ( $phrase =~ /$sep/ && $incr_d );
            my $head_full = $head . "_" . $cat_h . "_" . $pos_h
                if ( $phrase =~ /$sep/ && $incr_d );
            my $dep_full = $dep . "_" . $cat_d . "_" . $pos_d
                if ( $phrase =~ /$sep/ && $incr_h );

            $res .= "$cntxN $head&($rel_orig;$root_h_full;$dep_full) $freq\n"
                if ( $freq > 0 && $phrase =~ /$sep/ && $incr_h );
            $res .= "$cntxN $dep&($rel_orig;$head_full;$root_d_full) $freq\n"
                if ( $freq > 0 && $phrase =~ /$sep/ && $incr_d );
        }

        $iterCounter++;
    }

    return ( $res, $resFr );
}

sub tDep {
    my @target = split( "\n", shift(@_) );
    my @tHead  = split( "\n", shift(@_) );

    my $Dico = shift(@_);
    my $Trad = shift(@_);
    my $Cntx = shift(@_);

    my $res   = "";
    my $resFr = "";

    my $th=50;

    my $sep = "&";
    my $ling="S";

    my $dep;
    my $head;
    my $rel;
    my $rel_orig;
    my $dep_orig;
    my $head_orig;
    my $root;
    my $incr_d;
    my $incr_h; ##incremental
    my $cat_h;
    my $pos_h;
    my $cat_d;
    my $pos_d;
    my $cat_r;
    my $pos_r;

    my %DicoA;
    my %incrTrad = ();
    my %incrDico = ();
    my %incrCntx = ();

    while (my $line = shift(@tHead)) { ##percorremos o vector incremental, que esta vazio se começamos a processar a frase!
        chomp $line;
        my ($cntx_bil, $word, $freq) = split (" ", $line);

        $word =~ s/([^&]+)&//;
        $incrDico{$word}{$cntx_bil} = $freq;

        my ($cntx1, $cntx2) = split (";", $cntx_bil);
        $incrTrad{$cntx1}{$cntx2} = ${$Trad}{$cntx1}{$cntx2} + 1;

        $incrCntx{$cntx_bil}{$word} = $freq;
    }

    while (my $phrase = shift(@target)) {
        chomp $phrase;

        if ($phrase !~ /$sep/) {
            $phrase =~ s/^\(([^\)]+)\)$/$1/; ##borrar parenteses da analise
            ($rel_orig, $head_orig, $dep_orig) = split (";", $phrase);
            ($head, $cat_h, $pos_h) = split ("_", $head_orig);
            ($dep, $cat_d, $pos_d) = split ("_", $dep_orig);
            ($rel, $cat_r, $pos_r) = split ("_", $rel_orig);
        }
        else {
            my @phr = split ($sep, $phrase);
            my $last = $#phr;
            my $prev = $#phr - 1;
            $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
            $phr[$prev] =~ s/^\(([^\)]+)\)$/$1/;
            ($rel_orig, $h1, $d1) = split (";", $phr[$last]);
            ($r2, $h2, $d2) = split (";", $phr[$prev]);
            if ($h1 eq $h2) {
                $incr_h=1;
                $head = $phrase;
                my $regex_head = quotemeta($phr[$last]);
                $head =~ s/&\($regex_head\)$//;
                ($root, $cat_h, $pos_h) = split ("_", $h1);
                ($dep, $cat_d, $pos_d) = split ("_", $d1);
                ($rel, $cat_r, $pos_r) = split ("_", $rel_orig);
            }
            elsif ($d1 eq $d2 || $d1 eq $h2 || $h1 eq $d2) {
                $incr_d=1;
                $dep = $phrase;
                my $regex_dep = quotemeta($phr[$last]);
                $dep =~ s/&\($regex_dep\)$//;
                ($head, $cat_h, $pos_h) = split ("_", $h1);
                ($root, $cat_d, $pos_d) = split ("_", $d1);
                ($rel, $cat_r, $pos_r) = split ("_", $rel_orig);
            }
            else{
                die ("No incrementality. Stop\n");
            }
        }

        my $freq=1;
        my %found;
        my $c1="";
        my $cntx_dep="";

        $rel = removeLing ($rel,$ling);

        if ($incr_d || $phrase !~ /$sep/) {
            $c1 = $rel . "_down_" . $head;
        }
        elsif ($incr_h && $phrase =~ /$sep/) {
            $c1 = $rel . "_down_" . $root;
        }

        my $repeated = "";
        foreach my $c2 ( keys %{{%{${$Trad}{$c1}}, %{$incrTrad{$c1}}}} ) {
            $cntx_dep = $c2 . ";" . $c1;

            if(exists($incrDico{$dep}{$cntx_dep})) {
                $resFr .= "$c1 $dep $incrDico{$dep}{$cntx_dep}\n";
                $repeated = "$c1 $dep $incrDico{$dep}{$cntx_dep}\n";
            } elsif(exists(${$Dico}{$dep}{$cntx_dep})) {
                $resFr .= "$c1 $dep ${$Dico}{$dep}{$cntx_dep}\n";
                $repeated = "$c1 $dep ${$Dico}{$dep}{$cntx_dep}\n";
            }

            if(exists($incrDico{$root}{$cntx_dep})) {
                $resFr .= "$c1 $root $incrDico{$root}{$cntx_dep}\n";
            } elsif(exists(${$Dico}{$root}{$cntx_dep})) {
                $resFr .= "$c1 $root ${$Dico}{$root}{$cntx_dep}\n";
            }

            $resFr .= $repeated;

            my $count=0;
            my $temp = clone(${$Cntx}{$cntx_dep});
            @{$temp}{keys %{$incrCntx{$cntx_dep}}} = values %{$incrCntx{$cntx_dep}};

            foreach my $wordA ( sort { ${$temp}{$b} <=> ${$temp}{$a}  } keys %{$temp}) {
                if ($count <= $th) {
                    if ($wordA eq $dep || $wordA eq $root) {next}
                    $count++;

                    foreach my $cntxA  ( keys %{{%{${$Dico}{$wordA}}, %{$incrDico{$wordA}}}} ) {
                        if(exists($incrDico{$wordA}{$cntxA})) {
                            $DicoA{$phrase}{$cntxA} += $incrDico{$wordA}{$cntxA};
                        } elsif(exists(${$Dico}{$wordA}{$cntxA})) {
                            $DicoA{$phrase}{$cntxA} += ${$Dico}{$wordA}{$cntxA};
                        }
                    }
                }
            }
        }

        foreach my $cntxN ( keys %{{%{${$Dico}{$dep} }, %{$incrDico{$dep}}}}) {
            if(exists($incrDico{$dep}{$cntxN})) {
                $freq = $DicoA{$phrase}{$cntxN} * $incrDico{$dep}{$cntxN};
            } elsif(exists(${$Dico}{$dep}{$cntxN})) {
                $freq = $DicoA{$phrase}{$cntxN} * ${$Dico}{$dep}{$cntxN};
            }

            $res .= "$cntxN ($phrase) $freq\n" if ($freq >0 &&  $phrase !~ /$sep/ );

            my $root_h_full = $root . "_" . $cat_h . "_" . $pos_h if ($phrase =~ /$sep/ && $incr_h);
            my $root_d_full = $root . "_" . $cat_d . "_" . $pos_d if ($phrase =~ /$sep/ && $incr_d);
            my $head_full = $head . "_" . $cat_h . "_" . $pos_h if ($phrase =~ /$sep/ && $incr_d);
            my $dep_full = $dep . "_" . $cat_d . "_" . $pos_d if ($phrase =~ /$sep/ && $incr_h);

            $res .= "$cntxN $head&($rel_orig;$root_h_full;$dep_full) $freq\n" if ($freq >0 &&  $phrase =~ /$sep/ && $incr_h );
            $res .= "$cntxN $dep&($rel_orig;$head_full;$root_d_full) $freq\n" if ($freq >0 &&  $phrase =~ /$sep/ && $incr_d);
        }
    }

    return ($res, $resFr);
}

sub sHead {
    my $res  = "";
    my $arg1 = shift(@_);           ### vector da phrase incremental
    @file = split( "\n", $arg1 );

    my $phrase = shift(@_);
    my $Dico = shift(@_);
    my $Trad = shift(@_);
    my $Cntx = shift(@_);

    my $th   = 50;
    my $sep  = "&";                 ##separador de analises
    my $ling = "E";

    my $dep;
    my $head;
    my $rel;
    my $rel_orig;
    my $dep_orig;
    my $head_orig;
    my $root;
    my $incr_d;
    my $incr_h;                     ##incremental
    my $cat_h;
    my $pos_h;
    my $cat_d;
    my $pos_d;
    my $cat_r;
    my $pos_r;

    my %DicoH2 = ();
    my %incrTrad = ();
    my %incrDico = ();
    my %incrCntx = ();

    if ( $phrase !~ /&/ ) {
        $phrase =~ s/^\(([^\)]+)\)$/$1/;    ##borrar parenteses da analise
        ( $rel_orig, $head_orig, $dep_orig ) = split( ";", $phrase );
        ( $head,     $cat_h,     $pos_h )    = split( "_", $head_orig );
        ( $dep,      $cat_d,     $pos_d )    = split( "_", $dep_orig );
        ( $rel,      $cat_r,     $pos_r )    = split( "_", $rel_orig );
    }
    else {
        my @phr  = split( $sep, $phrase );
        my $last = $#phr;
        my $prev = $#phr - 1;
        $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
        $phr[$prev] =~ s/^\(([^\)]+)\)$/$1/;
        ( $rel_orig, $h1, $d1 ) = split( ";", $phr[$last] );
        ( $r2,       $h2, $d2 ) = split( ";", $phr[$prev] );
        if ( $h1 eq $h2 ) {
            $incr_h = 1;

            $head = $phrase;
            my $regex_head = quotemeta($phr[$last]);
            $head =~ s/&\($regex\)$//;

            ( $root, $cat_h, $pos_h ) = split( "_", $h1 );
            ( $dep,  $cat_d, $pos_d ) = split( "_", $d1 );
            ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );

        }
        elsif ( $d1 eq $d2 || $d1 eq $h2 || $h1 eq $d2 ) {
            $incr_d = 1;

            $dep = $phrase;
            my $regex_dep = quotemeta($phr[$last]);
            $dep =~ s/&\($regex_dep\)$//;
            ( $head, $cat_h, $pos_h ) = split( "_", $h1 );
            ( $root, $cat_d, $pos_d ) = split( "_", $d1 );
            ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
        }
        else {
            die("No incrementality. Stop\n");
        }
    }

    while ( my $line = shift(@file) )
    { ##percorremos o vector incremental, que esta vazio se começamos a processar a frase!
        chomp $line;
        my ( $cntx_bil, $word, $freq ) = split( " ", $line );
        $word =~ s/([^&]+)&//;
        $incrDico{$word}{$cntx_bil} = $freq;

        my ( $cntx1, $cntx2 ) = split( ";", $cntx_bil );
        $incrTrad{$cntx1}{$cntx2} = ${$Trad}{$cntx1}{$cntx2} + 1;

        $incrCntx{$cntx_bil}{$word} = $freq;
    }

    my $freq = 1;
    my %found;
    my $cntx_dep = "";
    ##Construiçao do vector indirecto (soma de vectores)

    $rel = removeLing( $rel, $ling );

    if ( $incr_h || $phrase !~ /$sep/ ) {
        $c1 = $rel . "_up_" . $dep;
    }
    elsif ( $incr_d && $phrase =~ /$sep/ ) {
        $c1 = $rel . "_up_" . $root;
    }

    foreach my $c2 ( keys %{{%{${$Trad}{$c1}}, %{$incrTrad{$c1}}}} )
    {    #buscamos as traduçoes do contexto do dep
        my $count = 0;
        $cntx_dep = $c1 . ";" . $c2;

        my $temp = clone(${$Cntx}{$cntx_dep});
        @{$temp}{keys %{$incrCntx{$cntx_dep}}} = values %{$incrCntx{$cntx_dep}};

        foreach my $wordDEP (
                sort { ${$temp}{$b} <=> ${$temp}{$a}  } keys %{$temp}
            )
        {    ##conjunto de heads relacionados como o dep na dependencia c1

            if ( $count <= $th ) {
                if ( $wordDEP eq $head || $wordDEP eq $root ) { next }
                $count++;

                foreach my $cntxH2  ( keys %{{%{${$Dico}{$wordDEP}}, %{$incrDico{$wordDEP}}}} )
                { ##aqui construimos o conjunto de contextos dos head associados ao dep
                    if(exists($incrDico{$wordDEP}{$cntxH2})) {
                        $DicoH2{$cntxH2} += $incrDico{$wordDEP}{$cntxH2};
                    } elsif(exists(${$Dico}{$wordDEP}{$cntxH2})) {
                        $DicoH2{$cntxH2} += ${$Dico}{$wordDEP}{$cntxH2};
                    }
                }
            }
        }
    }

    ##Multiplicaçao do vector indirecto (DicoH2) e o directo do head (Dico)
    foreach my $cntxHEAD ( keys %{{%{${$Dico}{$head} }, %{$incrDico{$head}}}})
    {             ##percorremos o conjunto de contextos bilingues do head
        if(exists($incrDico{$head}{$cntxHEAD})) {
            $freq = $DicoH2{$cntxHEAD} * $incrDico{$head}{$cntxHEAD};
        } elsif(exists(${$Dico}{$head}{$cntxHEAD})) {
            $freq = $DicoH2{$cntxHEAD} * ${$Dico}{$head}{$cntxHEAD};
        }

        $res .= "$cntxHEAD ($phrase) $freq\n"
          if ( $freq > 0 && $phrase !~ /$sep/ );
        my $root_h_full = $root . "_" . $cat_h . "_" . $pos_h
          if ( $phrase =~ /$sep/ && $incr_h );
        my $root_d_full = $root . "_" . $cat_d . "_" . $pos_d
          if ( $phrase =~ /$sep/ && $incr_d );
        my $head_full = $head . "_" . $cat_h . "_" . $pos_h
          if ( $phrase =~ /$sep/ && $incr_d );
        my $dep_full = $dep . "_" . $cat_d . "_" . $pos_d
          if ( $phrase =~ /$sep/ && $incr_h );
        $res .= "$cntxHEAD $head&($rel_orig;$root_h_full;$dep_full) $freq\n"
          if ( $freq > 0 && $phrase =~ /$sep/ && $incr_h );
        $res .= "$cntxHEAD $dep&($rel_orig;$head_full;$root_d_full) $freq\n"
          if ( $freq > 0 && $phrase =~ /$sep/ && $incr_d );
    }

    return $res;
}

sub sDep {
    my $res = "";
    my @sHead = split( "\n", shift(@_) );    ### vector da phrase incremental

    my $phrase = shift(@_);

    my $Dico = shift(@_);
    my $Trad = shift(@_);
    my $Cntx = shift(@_);

    my $th   = 50;
    my $sep  = "&";    ##separador de analises
    my $ling = "E";

    my $dep;
    my $head;
    my $rel;
    my $rel_orig;
    my $dep_orig;
    my $head_orig;
    my $root;
    my $incr_d;
    my $incr_h;        ##incremental
    my $cat_h;
    my $pos_h;
    my $cat_d;
    my $pos_d;
    my $cat_r;
    my $pos_r;

    my %DicoH2;
    my %incrTrad = ();
    my %incrDico = ();
    my %incrCntx = ();

    if ( $phrase !~ /&/ ) {
        $phrase =~ s/^\(([^\)]+)\)$/$1/;    ##borrar parenteses da analise
        ( $rel_orig, $head_orig, $dep_orig ) = split( ";", $phrase );
        ( $head,     $cat_h,     $pos_h )    = split( "_", $head_orig );
        ( $dep,      $cat_d,     $pos_d )    = split( "_", $dep_orig );
        ( $rel,      $cat_r,     $pos_r )    = split( "_", $rel_orig );
    }
    else {
        my @phr  = split( $sep, $phrase );
        my $last = $#phr;
        my $prev = $#phr - 1;
        $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
        $phr[$prev] =~ s/^\(([^\)]+)\)$/$1/;
        ( $rel_orig, $h1, $d1 ) = split( ";", $phr[$last] );
        ( $r2,       $h2, $d2 ) = split( ";", $phr[$prev] );
        if ( $h1 eq $h2 ) {
            $incr_h = 1;

            $head = $phrase;
            my $regex_head = quotemeta($phr[$last]);
            $head =~ s/&\($regex_head\)$//;
            ( $root, $cat_h, $pos_h ) = split( "_", $h1 );
            ( $dep,  $cat_d, $pos_d ) = split( "_", $d1 );
            ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
        }
        elsif ( $d1 eq $d2 || $d1 eq $h2 || $h1 eq $d2 ) {
            $incr_d = 1;

            $dep = $phrase;
            my $regex_dep = quotemeta($phr[$last]);
            $dep =~ s/&\($regex_dep\)$//;
            ( $head, $cat_h, $pos_h ) = split( "_", $h1 );
            ( $root, $cat_d, $pos_d ) = split( "_", $d1 );
            ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
        }
        else {
            die("No incrementality. Stop\n");
        }

    }

    while ( my $line = shift(@sHead) )
    { ##percorremos o vector incremental, que esta vazio se começamos a processar a frase!
        chomp $line;
        my ( $cntx_bil, $word, $freq ) = split( " ", $line );

        $word =~ s/([^&]+)&//;
        $incrDico{$word}{$cntx_bil} = $freq;

        my ( $cntx1, $cntx2 ) = split( ";", $cntx_bil );
        $incrTrad{$cntx1}{$cntx2} = ${$Trad}{$cntx1}{$cntx2} + 1;

        $incrCntx{$cntx_bil}{$word} = $freq;
    }

    my $freq = 1;
    my %found;
    my $cntx_head = "";
    ##Construiçao do vector indirecto (soma de vectores)

    $rel = removeLing( $rel, $ling );

    if ( $incr_d || $phrase !~ /$sep/ ) {
        $c1 = $rel . "_down_" . $head;
    }
    elsif ( $incr_h && $phrase =~ /$sep/ ) {
        $c1 = $rel . "_down_" . $root;
    }

    foreach my $c2 ( keys %{{%{${$Trad}{$c1}}, %{$incrTrad{$c1}}}} )
    {    #buscamos as traduçoes do contexto do dep
        my $count = 0;
        $cntx_head = $c1 . ";" . $c2;

        my $temp = clone(${$Cntx}{$cntx_head});
        @{$temp}{keys %{$incrCntx{$cntx_head}}} = values %{$incrCntx{$cntx_head}};

        foreach my $wordDEP (
                sort { ${$temp}{$b} <=> ${$temp}{$a}  } keys %{$temp}
            )
        {    ##conjunto de heads relacionados como o dep na dependencia c1
            if ( $count <= $th ) {
                if ( $wordDEP eq $dep || $wordDEP eq $root ) { next }
                $count++;

                foreach my $cntxH2  ( keys %{{%{${$Dico}{$wordDEP}}, %{$incrDico{$wordDEP}}}} )
                { ##aqui construimos o conjunto de contextos dos head associados ao dep
                    if(exists($incrDico{$wordDEP}{$cntxH2})) {
                        $DicoH2{$cntxH2} += $incrDico{$wordDEP}{$cntxH2};
                    } elsif(exists(${$Dico}{$wordDEP}{$cntxH2})) {
                        $DicoH2{$cntxH2} += ${$Dico}{$wordDEP}{$cntxH2};
                    }
                }
            }
        }
    }

    ##Multiplicaçao do vector indirecto (DicoH2) e o directo do head (Dico)

    foreach my $cntxHEAD ( keys %{{%{${$Dico}{$dep} }, %{$incrDico{$dep}}}})
    {                   ##percorremos o conjunto de contextos bilingues do head
        if(exists($incrDico{$dep}{$cntxHEAD})) {
            $freq = $DicoH2{$cntxHEAD} * $incrDico{$dep}{$cntxHEAD};
        } elsif(exists(${$Dico}{$dep}{$cntxHEAD})) {
            $freq = $DicoH2{$cntxHEAD} * ${$Dico}{$dep}{$cntxHEAD};
        }

        $res .= "$cntxHEAD ($phrase) $freq\n"
          if ( $freq > 0 && $phrase !~ /$sep/ );
        my $root_h_full = $root . "_" . $cat_h . "_" . $pos_h
          if ( $phrase =~ /$sep/ && $incr_h );
        my $root_d_full = $root . "_" . $cat_d . "_" . $pos_d
          if ( $phrase =~ /$sep/ && $incr_d );
        my $head_full = $head . "_" . $cat_h . "_" . $pos_h
          if ( $phrase =~ /$sep/ && $incr_d );
        my $dep_full = $dep . "_" . $cat_d . "_" . $pos_d
          if ( $phrase =~ /$sep/ && $incr_h );
        $res .= "$cntxHEAD $head&($rel_orig;$root_h_full;$dep_full) $freq\n"
          if ( $freq > 0 && $phrase =~ /$sep/ && $incr_h );
        $res .= "$cntxHEAD $dep&($rel_orig;$head_full;$root_d_full) $freq\n"
          if ( $freq > 0 && $phrase =~ /$sep/ && $incr_d );
    }

    return $res;
}

sub trim {    #remove all leading and trailing spaces
    my ($str) = @_[0];

    $str =~ s/^\s*(.*\S)\s*$/$1/;
    return $str;
}

sub removeLing {    #remove all leading and trailing spaces
    my ($str) = @_[0];
    my ($l)   = @_[1];

    $str =~ s/\#$l$//;
    return $str;
}

sub addLing {       #remove all leading and trailing spaces
    my ($str)  = @_[0];
    my ($ling) = @_[1];

    $str =~ s/$/\#$ling/;
    return $str;
}

1;
