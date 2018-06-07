package Misc;
use Exporter;

our @ISA = qw( Exporter );

# these CAN be exported.
#our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( pares root similTotalFromChunks ranking toJson);

sub removeLangMark {
    #Toma a saida de thesaurusLocalByCntx.perl"
    my @text = split( " ", shift(@_) );
    my @cleanText;

    foreach my $word (@text) {
        $word = substr $word, 0, -2;
        $word =~ tr/@/ /; # replace @ by blank
        push @cleanText, $word;
    }

    return ( join " ", @cleanText );
}

sub toJson {
    my @rankingResults = split( "\n", shift(@_) );
    my $text           = shift(@_);
    my $rankingResults = "";

    if ( scalar @rankingResults > 0 ) {
        $rankingResults = $rankingResults[-1];
    }

    $rankingResults = removeLangMark($rankingResults);
    $rankingResults =
      "{\"source\": \"$text\", \"target\": \"$rankingResults\"}";

    return $rankingResults;
}

sub pares {
    my $res = "";

    my @input = split( "\n", shift(@_) );
    my $source = shift(@_);

    while ( my $line = shift(@input) ) {
        chomp $line;
        my ( $target, $pattern ) = split( '\t', $line );
        $res .= "$source $target\n";
    }

    return $res;
}

sub root {
    my $phrase = shift(@_);
    my $dir    = shift(@_);
    my $res    = "";

    my $sep = "&";

    if ( $phrase !~ /&/ ) {
        $phrase =~ s/^\(([^\)]+)\)$/$1/;    ##borrar parenteses da analise
        ( $rel,  $head_orig, $dep_orig ) = split( ";", $phrase );
        ( $head, $cat_h,     $pos_h )    = split( "_", $head_orig );
        ( $dep,  $cat_d,     $pos_d )    = split( "_", $dep_orig );
    }
    else {
        my @phr = split( $sep, $phrase );
        my $last = $#phr;
        $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
        ( $rel,  $h1,    $d1 )    = split( ";", $phr[$last] );
        ( $head, $cat_h, $pos_h ) = split( "_", $h1 );
        ( $dep,  $cat_d, $pos_d ) = split( "_", $d1 );
    }

    $cat_h = lc $cat_h;
    $cat_d = lc $cat_d;

    $res .= "$cat_h\n" if ( $dir eq "head" );
    $res .= "$cat_d\n" if ( $dir eq "dep" );

    return $res;
}

sub similTotalFromChunks {
    my @input = split( "\n", shift(@_) );
    my $comp  = shift(@_);
    my $th    = shift(@_);
    my @fr    = split( "\n", shift(@_) );
    my $res   = "";

    my ($comp1, $comp2, $source1, $source2, $target1, $target2) = "";
    my %Fr = ();

    my $N = 0;

    my $sep = "&";

    my $rel;
    my $dep;
    my $head;

    if ( $comp !~ /$sep/ ) {
        $comp1 = $comp;
    }
    else {
        my @phr  = split( $sep, $comp );
        my $last = $#phr;
        my $prev = $#phr - 1;
        $comp1 = $phr[$last];
        $comp2 = $phr[$prev];
    }

    while ( $line = shift(@fr) ) {
        my $d;
        my $h;
        chomp($line);
        my ( $cntx, $w, $simil ) = split( " ", $line );
        if ( $w =~ /;/ ) { next }
        my ( $r, $dir, $w2 ) = split( "_", $cntx );

        # print STDERR "---> #$dir# -- w:#$w2# - c:#$r#\n";
        if ( $dir eq "up" ) {
            $d = $w2;
            $h = $w;
        }
        elsif ( $dir eq "down" ) {
            $d = $w;
            $h = $w2;
        }

        my $ph = "($r;$h;$d)" if ( $h && $d );
        $Fr{$ph} = $simil if ( $h && $d );
    }

    my %Dict;
    foreach (@input) {
        my $line = $_;
        chomp($line);

        my ( $source, $target, $simil ) = split( " ", $line );

        if ( $source !~ /$sep/ ) {
            $source1 = $source;
        }
        else {
            my @phr  = split( $sep, $source );
            my $last = $#phr;
            my $prev = $#phr - 1;
            $source1 = $phr[$last];
            $source2 = $phr[$prev];

        }

        if ( $target !~ /$sep/ ) {
            $target1 = $target;
        }
        else {
            my @phr  = split( $sep, $target );
            my $last = $#phr;
            my $prev = $#phr - 1;
            $target1 = $phr[$last];
            $target2 = $phr[$prev];
        }

        if ( $source1 eq $comp1 ) {
            $Dict{$source1}{$target1} += $simil;
        }

        if ( $source2 && $source2 eq $comp2 ) {
            $Dict{$source2}{$target2} += $simil;
        }
        $N++;
    }

    foreach $w1 ( reverse keys %Dict ) {
        $count = 0;

        foreach $w2 (
                sort { $Dict{$w1}{$b} <=> $Dict{$w1}{$a} }
                keys %{ $Dict{$w1} }
            )
        {
            $sim  = 0;
            $sim1 = 0;
            $sim2 = 0;
            if ( $count <= $th && $w2 && $w1 ) {
                $sim1   = $Dict{$w1}{$w2} / $N;
                $w2_bis = $w2;
                $w2_bis =~ s/^\(//;
                $w2_bis =~ s/\)$//;

                my ( $r,       $h,   $d )   = split( ";", $w2_bis );
                my ( $h_clean, $c_h, $p_h ) = split( "_", $h );
                my ( $d_clean, $c_d, $p_d ) = split( "_", $d );
                ( $r_clean, $c_r, $p_r ) = split( "_", $r );
                $r_clean =~ s/#S//;
                $new_w2 = "($r_clean;$h_clean;$d_clean)";

                $sim2 = $Fr{$new_w2} / 2 if ( $Fr{$new_w2} );

                if ($sim2) {
                    $sim = $sim1 * $sim2;
                }
                else {
                    $sim = $sim1;
                }
                $res .= "$w1 $w2 $sim\n";
                $count++;
            }
        }
    }

    return $res;
}

sub ranking {
    my @in   = split( "\n", shift(@_) );
    my $res  = "";
    my $res2 = "";
    my $th   = 1;
    my $sep  = "&";
    my %Dict;
    my %Source;
    my %Target;
    my %final;
    my %Final;
    my %Final2;
    my %change;

    while ( $line = shift(@in) ) {
        chomp($line);
        ( $pal1, $pal2, $simil ) = split( " ", $line );
        $Dict{$pal1}{$pal2} += $simil;
    }

    foreach $w1 ( reverse keys %Dict ) {
        $count = 0;
        foreach $w2 (
                sort { $Dict{$w1}{$b} <=> $Dict{$w1}{$a} }
                keys %{ $Dict{$w1} }
            )
        {
            if ( $count < $th ) {
                $sim = $Dict{$w1}{$w2};
                $res .= "$w1 $w2 $sim\n";
                $count++;
            }
        }
    }

    my @input2 = split( "\n", $res );

    while ( $line = shift(@input2) ) {
        chomp($line);
        my ( $source, $target, $simil ) = split( " ", $line );
        my ($nexo_s, $nexo_t) = "";
        my ($rpos_s, $rpos_t) = "";

        $source =~ s/^\(([^\)]+)\)$/$1/;
        $target =~ s/^\(([^\)]+)\)$/$1/;

        my ( $rel_s, $h_s, $d_s ) = split( ";", $source );
        my ( $rel_t, $h_t, $d_t ) = split( ";", $target );

        my ( $head_s, $hcat_s, $hpos_s ) = split( "_", $h_s );
        my ( $dep_s,  $dcat_s, $dpos_s ) = split( "_", $d_s );
        my ( $head_t, $hcat_t, $hpos_t ) = split( "_", $h_t );
        my ( $dep_t,  $dcat_t, $dpos_t ) = split( "_", $d_t );

        $hpos_s = 0.1 if ( $hpos_s == 0 );
        $hpos_t = 0.1 if ( $hpos_t == 0 );
        $dpos_s = 0.1 if ( $dpos_s == 0 );
        $dpos_t = 0.1 if ( $dpos_t == 0 );

        #####Caso de relaçoes com nexo
        if ( $rel_s =~ /_/ ) {
            ( $rel_s, $rcat_s, $rpos_s ) = split( "_", $rel_s );
            if ( $rel_s =~ /\// ) {
                ( $rel_s, $nexo_s ) = split( '\/', $rel_s );
            }
            else {
                $nexo_s = $rel_s;
            }
        }
        if ( $rel_t =~ /_/ ) {
            ( $rel_t, $rcat_t, $rpos_t ) = split( "_", $rel_t );
            if ( $rel_t =~ /\// ) {
                ( $rel_t, $nexo_t ) = split( '\/', $rel_t );
            }
            else {
                $nexo_t = $rel_t;
            }
        }

        #reordenar Lmod/Rmod...
        if (
            (
                   ( $rel_s =~ /^L/ || $rel_s =~ /L$/ )
                && ( $rel_t =~ /^R/ || $rel_t =~ /R$/ )
            )
            || ( $rel_s =~ /^modN/ )
          )
        {
            $change{$hpos_t} = $dpos_t;
            $change{$dpos_t} = $hpos_t;
        }
        elsif (( $rel_s =~ /^R/ || $rel_s =~ /R$/ )
            && ( $rel_t =~ /^L/ || $rel_t =~ /L$/ ) )
        {
            $change{$hpos_t} = $dpos_t;
            $change{$dpos_t} = $hpos_t;
        }

        $Source{$hpos_s}{$head_s} = $simil;
        $Source{$dpos_s}{$dep_s}  = $simil;
        $Source{$rpos_s}{$nexo_s} = $simil;
        $Target{$hpos_t}{$head_t} = $simil;
        $Target{$dpos_t}{$dep_t}  = $simil;
        $Target{$rpos_t}{$nexo_t} = $simil;

    }

    foreach my $pos (sort {$a<=>$b}keys %Source  ) {
        $count = 0;
        foreach $t (
                sort { $Source{$pos}{$b} <=> $Source{$pos}{$a} }
                keys %{ $Source{$pos} }
            )
        {
            if ( $count < 1 )
            {    ##selecionar o primeiro se houver 2 ou mais na mesma posiçao
                $res2 .= "$t ";
                $count++;
            }
        }
    }

    $res2 .= "\n";

    $i = 0;
    foreach my $pos (sort {$a<=>$b} keys %Target  ) {
        $count = 0;

        foreach $t (
                sort { $Target{$pos}{$b} <=> $Target{$pos}{$a} }
                keys %{ $Target{$pos} }
            )
        {
            if ( $count < 1 )
            {    ##selecionar o primeiro se houver 2 ou mais na mesma posiçao
                if ( $change{$i} ) {
                    $final{ $change{$i} } = $t;
                }
                else {
                    $final{$i} = $t;
                }
                $count++;
            }
        }

        $i++;
    }

    $i = 0;
    foreach my $pos (sort {$a<=>$b} keys %Target  ) {
        $count = 0;

        foreach $t (
                sort { $Target{$pos}{$b} <=> $Target{$pos}{$a} }
                keys %{ $Target{$pos} }
            )
        {
            if ( $count < 1 )
            {    ##selecionar o primeiro se houver 2 ou mais na mesma posiçao
                $Final{$pos} = $t;
                $count++;
            }
        }

        $i++;
    }

    foreach my $pos (sort {$a<=>$b} keys %final  ) {
        $res2 .= "$final{$pos} ";
    }
    $res2 .= "\n";

    foreach my $pos ( sort keys %Final ) {
        if ( $change{$pos} ) {
            $Final2{ $change{$pos} } = $Final{$pos};
        }
        else {
            $Final2{$pos} = $Final{$pos};
        }
    }

    foreach my $pos (sort {$a<=>$b} keys %Final2  ) {
        $res2 .= "$Final2{$pos} ";
    }

    $res2 .= "\n";

    return $res2;
}

1;
