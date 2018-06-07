package BuildTarget;

#use strict;
use Exporter;

our @ISA = qw( Exporter );

# these CAN be exported.
#our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( buildTargetNew );

our $sep = "&";

sub buildTarget {
    my $res = "";

    # Opening main files
    my @dico    = split( "\n", shift(@_) );
    my @file    = split( "\n", shift(@_) );
    my @results = split( "\n", shift(@_) );

    # Declarations
    my $phrase = shift(@_);

    my $S   = "E";
    my $T   = "S";
    my $sep = "&";

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
    my $COMP = 0;
    ##if phrase non tem &, entao hai que buscar as traduçoes do head e o dep no dico, senom, so do head se incr_h ou do dep se incr_d (as da phrase venhem do ficheiro que falta...)
    if ( $phrase !~ /$sep/ ) {
        $phrase =~ s/^\(([^\)]+)\)$/$1/;    ##borrar parenteses da analise
        ( $rel_orig, $head_orig, $dep_orig ) = split( ";", $phrase );
        ( $head,     $cat_h,     $pos_h )    = split( "_", $head_orig );
        ( $dep,      $cat_d,     $pos_d )    = split( "_", $dep_orig );
        ( $rel,      $cat_r,     $pos_r )    = split( "_", $rel_orig );
    }
    else {
        $COMP = 1;
        my @phr  = split( $sep, $phrase );
        my $last = $#phr;
        my $prev = $#phr - 1;
        $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
        $phr[$prev] =~ s/^\(([^\)]+)\)$/$1/;
        ( $rel_orig, $h1, $d1 ) = split( ";", $phr[$last] );
        ( $r2,       $h2, $d2 ) = split( ";", $phr[$prev] );

        if ( $h1 eq $h2 ) {
            $incr_h = 1;
            $head   = "($phr[$prev])";
            ( $root, $cat_h, $pos_h ) = split( "_", $h1 );
            ( $dep,  $cat_d, $pos_d ) = split( "_", $d1 );
            ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
        }
        elsif ( $d1 eq $d2 || $d1 eq $h2 || $h1 eq $d2 ) {
            $incr_d = 1;
            $dep    = "($phr[$prev])";
            ( $head, $cat_h, $pos_h ) = split( "_", $h1 );
            ( $root, $cat_d, $pos_d ) = split( "_", $d1 );
            ( $rel,  $cat_r, $pos_r ) = split( "_", $rel_orig );
        }
        else {
            die("No incrementality. Stop\n");
        }
    }

    $head =~ s/#${S}$//;
    $dep =~ s/#${S}$//;
    $root =~ s/#${S}$//;

    my %Lemmas;
    my %Target;

    if ( $phrase =~ /$sep/ ) {
        while ( my $line = shift(@results) ) {    ##le target.txt
            chomp $line;
            my ( $source, $target, $sim ) = split( " ", $line );
            $target =~ s/^\(([^\)]+)\)$/$1/;
            my ( $r_t, $h_t, $d_t ) = split( ";", $target );
            $Lemmas{$h_t}{$d_t}++;
        }

        while ( my $ph = shift(@file) ) {         ##le target.txt
            chomp $ph;
            $ph =~ s/([^&]+)&//;
            foreach my $h ( keys %Lemmas ) {
                my $regex_h = quotemeta($h);
                foreach my $d ( keys %{ $Lemmas{$h} } ) {
                    my $regex_d = quotemeta($d);
                    if ( $ph =~ /$regex_h/ && $ph =~ /$regex_d/ ) {
                        $Target{$ph}++;
                        next;
                    }
                }
            }
        }
    }

    if ($COMP) {
        if ($incr_h) {
            $head = $root;
        }
        elsif ($incr_d) {
            $dep = $root;
        }
    }

    my %NounH;
    my %VerbH;
    my %AdjH;
    my %NounD;
    my %VerbD;
    my %AdjD;

    while ( my $line = shift(@dico) ) {
        chomp $line;
        my ( $source, $target, $cat ) = split( '\t', $line );
        $source = trim($source);
        $target = trim($target);

        if ( !$COMP ) {
            if ( $source eq $head && $cat =~ /^N/ ) {
                $NounH{$target}++;
            }
            elsif ( $source eq $head && $cat =~ /^V/ ) {
                $VerbH{$target}++;
            }
            elsif ( $source eq $head && $cat =~ /^ADJ/ ) {
                $AdjH{$target}++;
            }

            if ( $source eq $dep && $cat =~ /^N/ ) {
                $NounD{$target}++;
            }
            elsif ( $source eq $dep && $cat =~ /^V/ ) {
                $VerbD{$target}++;
            }
            elsif ( $source eq $dep && $cat =~ /^ADJ/ ) {
                $AdjD{$target}++;
            }
        }
        elsif ($COMP) {
            if ( $source eq $head && $cat_h =~ /^N/ && $cat =~ /^N/ ) {
                $NounH{$target}++;
            }
            elsif ( $source eq $head && $cat_h =~ /^V/ && $cat =~ /^V/ ) {
                $VerbH{$target}++;
            }
            elsif ( $source eq $head && $cat_h =~ /^ADJ/ && $cat =~ /^A/ ) {
                $AdjH{$target}++;
            }

            if ( $source eq $dep && $cat_d =~ /^N/ && $cat =~ /^N/ ) {
                $NounD{$target}++;
            }
            elsif ( $source eq $dep && $cat_d =~ /^V/ && $cat =~ /^V/ ) {
                $VerbD{$target}++;
            }
            elsif ( $source eq $dep && $cat_d =~ /^ADJ/ && $cat =~ /^A/ ) {
                $AdjD{$target}++;
            }
        }
    }

    ##Novas regras para os casos onde nom haja adjectivos nem nomes no dico
    if (!%AdjD) {
        $AdjD{"grande"} = 1;
    }
    elsif (!%AdjH) {
        $AdjH{"grande"} = 1;
    }
    if (!%NounD) {
        $NounD{"cosa"} = 1;
    }
    elsif (!%NounH) {
        $NounH{"cosa"} = 1;
    }

    if ( $rel =~ /(Lobj|Subj|Robj|Dobj)/ && $cat_d =~ /^N/ ) {
        foreach my $n ( keys %NounD ) {
            if ( $n eq "" ) { next }

            foreach my $v ( keys %VerbH ) {
                if ( $v eq "" ) { next }
                my $verb = $v . "#$T" . "_" . $cat_h . "_" . $pos_h;
                my $noun = $n . "#$T" . "_" . $cat_d . "_" . $pos_d;
                $res .= "($rel;$verb;$noun)\n" if ( !$COMP );
                if ($COMP) {
                    foreach my $incr ( keys %Target ) {
                        $res .= "$incr&($rel;$verb;$noun)\n"
                            if ( Root( $noun, $incr ) || Root( $verb, $incr ) );
                    }
                }
            }
        }
    }
    elsif ( $rel =~ /(Lobj|Subj|Robj|Dobj)/ && $cat_d =~ /^V/ ) {
        foreach my $v2 ( keys %VerbD ) {
            if ( $v2 eq "" ) { next }

            foreach my $v ( keys %VerbH ) {
                if ( $v eq "" ) { next }
                my $verb  = $v . "#$T" . "_" . $cat_h . "_" . $pos_h;
                my $verb2 = $v2 . "#$T" . "_" . $cat_d . "_" . $pos_d;
                $res .= "($rel;$verb;$verb2)\n" if ( !$COMP );
                if ($COMP) {
                    foreach my $incr ( keys %Target ) {
                        $res .= "$incr&($rel;$verb;$verb2)\n"
                            if ( Root( $verb2, $incr ) || Root( $verb, $incr ) );
                    }
                }
            }
        }
    }
    elsif ( $rel =~ /(Lmod|Rmod|AdjnL|AdjnR)/ ) {
        $rel1 = "Lmod";
        $rel2 = "Rmod";
        foreach my $a ( keys %AdjD ) {
            if ( $a eq "" ) { next }
            foreach my $n ( keys %NounH ) {
                if ( $n eq "" ) { next }
                my $adj  = $a . "#$T" . "_" . $cat_d . "_" . $pos_d;
                my $noun = $n . "#$T" . "_" . $cat_h . "_" . $pos_h;

                $res .= "($rel1;$noun;$adj)\n" if ( !$COMP );
                $res .= "($rel2;$noun;$adj)\n" if ( !$COMP );
                if ($COMP) {
                    foreach my $incr ( keys %Target ) {
                        $res .= "$incr&($rel1;$noun;$adj)\n"
                          if ( Root( $noun, $incr ) || Root( $adj, $incr ) );
                        $res .= "$incr&($rel2;$noun;$adj)\n"
                          if ( Root( $noun, $incr ) || Root( $adj, $incr ) );
                    }
                }
            }
        }
    }
    elsif ( $rel =~ /(modN)/ )
    {    ##cuidado com outros nomes: if AdjnL and cat_d = NOUN
        $rel1  = "modN";
        $pos_r = $pos_d + 0.5;
        $rel2  = "Cprep\/de#S_PRP_$pos_r";
        foreach my $n_d ( keys %NounD ) {
            if ( $n_d eq "" ) { next }
            foreach my $n_h ( keys %NounH ) {
                if ( $n_h eq "" ) { next }
                my $noun_d = $n_d . "#$T" . "_" . $cat_d . "_" . $pos_d;
                my $noun_h = $n_h . "#$T" . "_" . $cat_h . "_" . $pos_h;

                $res .= "($rel1;$noun_h;$noun_d)\n" if ( !$COMP );
                $res .= "($rel2;$noun_h;$noun_d)\n" if ( !$COMP );
                if ($COMP) {
                    foreach my $incr ( keys %Target ) {
                        $res .= "$incr&($rel1;$noun_h;$noun_d)\n"
                          if ( Root( $noun_h, $incr )
                            || Root( $noun_d, $incr ) );
                        $res .= "$incr&($rel2;$noun_h;$noun_d)\n"
                          if ( Root( $noun_h, $incr )
                            || Root( $noun_d, $incr ) );
                    }
                }
            }
        }
    }
    elsif ( $rel =~ /(^[iI]obj|Circ|Reg)/ ) {
        #cuidado com os Cprep/of_PRP_2 os os casos of_PRP_2
        ( $rel, $nexo ) = split( '\/', $rel );
        @rel = trad($nexo);
        foreach my $n_d ( keys %NounD ) {
            if ( $n_d eq "" ) { next }
            foreach my $v_h ( keys %VerbH ) {
                if ( $v_h eq "" ) { next }
                my $noun_d = $n_d . "#$T" . "_" . $cat_d . "_" . $pos_d;
                my $verb_h = $v_h . "#$T" . "_" . $cat_h . "_" . $pos_h;

                foreach my $r (@rel) {
                    my $r_new = $rel . "/" . $r . "_" . $cat_r . "_" . $pos_r;
                    $res .= "($r_new;$verb_h;$noun_d)\n" if ( !$COMP );
                }
                if ($COMP) {
                    foreach my $incr ( keys %Target ) {
                        foreach my $r (@rel) {
                            my $r_new =
                                $rel . "/" . $r . "_" . $cat_r . "_" . $pos_r;
                            $res .= "$incr&($r_new;$verb_h;$noun_d)\n"
                                if ( Root( $verb_h, $incr )
                                || Root( $noun_d, $incr ) );
                        }
                    }
                }
            }
        }
    }
    elsif ( $rel_orig =~ /(_|Cprep)/ ) {
        #cuidado com os Cprep/of_PRP_2 os os casos of_PRP_2
        if ( $rel =~ /\// ) {
            ( $rel, $nexo ) = split( '\/', $rel );
            @rel = trad($nexo);
        }
        else {
            @rel = trad($rel);
        }

        foreach my $n_d ( keys %NounD ) {
            if ( $n_d eq "" ) { next }
            foreach my $n_h ( keys %NounH ) {
                if ( $n_h eq "" ) { next }
                my $noun_d = $n_d . "#$T" . "_" . $cat_d . "_" . $pos_d;
                my $noun_h = $n_h . "#$T" . "_" . $cat_h . "_" . $pos_h;

                foreach my $r (@rel) {
                    my $r_new = $rel . "/" . $r . "_" . $cat_r . "_" . $pos_r;
                    $res .= "($r_new;$noun_h;$noun_d)\n" if ( !$COMP );
                }
                if ($COMP) {
                    foreach my $incr ( keys %Target ) {
                        foreach my $r (@rel) {
                            my $r_new =
                                $rel . "/" . $r . "_" . $cat_r . "_" . $pos_r;
                            $res .= "$incr&($r_new;$noun_h;$noun_d)\n"
                                if ( Root( $noun_h, $incr )
                                || Root( $noun_d, $incr ) );
                        }
                    }
                }
            }
        }
    }

    return $res;
}

sub Root {
    my ($w)    = @_[0];
    my ($phr)  = @_[1];
    my $result = 0;
    @phr = split( $sep, $phr );
    my $last = $#phr;

    $phr[$last] =~ s/^\(([^\)]+)\)$/$1/;
    my ( $rel, $head_full, $dep_full ) = split( ";", $phr[$last] );

    my ( $h, $c_h, $p_h ) = split( "_", $head_full );
    my ( $d, $c_d, $p_d ) = split( "_", $dep_full );
    if ( $w eq $head_full ) {
        $result = 1;
    }
    elsif ( $w eq $dep_full ) {
        $result = 1;
    }

    return $result;
}

sub trim {    #remove all leading and trailing spaces
    my ($str) = @_[0];

    $str =~ s/^\s*(.*\S)\s*$/$1/;

    return $str;
}

sub trad {    #traduz preposiçoes en-es
    my ($r) = @_[0];
    my @result;

    if ( $r eq "of#E" ) {
        $result[0] = "de#S";
    }
    elsif ( $r eq "from#E" ) {
        $result[0] = "de#S";
        $result[1] = "desde#S";
    }
    elsif ( $r eq "with#E" ) {
        $result[0] = "con#S";
    }
    elsif ( $r eq "by#E" ) {
        $result[0] = "por#S";
    }
    elsif ( $r eq "for#E" ) {
        $result[0] = "para#S";
    }
    elsif ( $r eq "about#E" ) {
        $result[0] = "sobre#S";
    }
    elsif ( $r eq "in#E" ) {
        $result[0] = "en#S";
    }
    elsif ( $r eq "at#E" ) {
        $result[0] = "en#S";
        $result[1] = "a#S";
    }
    elsif ( $r eq "to#E" ) {
        $result[0] = "a#S";
    }
    elsif ( $r eq "on#E" ) {
        $result[0] = "sobre#S";
        $result[1] = "en#S";
    }
    elsif ( $r eq "along#E" ) {
        $result[0] = "por#S";
    }

    return @result;
}

1;
