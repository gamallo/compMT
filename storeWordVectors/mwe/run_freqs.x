#/bin/bash

#./run_freqs.x wiki en EN

DIR=~/Similarity/Similarity_Bilingual


PROGSDIR=$DIR/progs
TMPDIR=$DIR/tmp
INPUTDIR=$DIR/tagged
OUTPUTDIR=$DIR/freq


#####PARAMETERS##########

PREFFIX=$1
LING=$2
TAG=$3

########################

##./run_freqs.x mw es S

#input: mw-es.txt

INPUTFILE=${INPUTDIR}/${PREFFIX}"-"${LING}.txt ;

#outputs:

OUTPUTFILE=$OUTPUTDIR"/freq_"${PREFFIX}"-"$LING".txt.gz"

#cat $INPUTFILE | $PROGSDIR/filtering_words_from_tagged.perl > tmp/words-$LING
cat $INPUTFILE |$PROGSDIR/AdapterFreeling-${LING}.perl |

                 $PROGSDIR/parser-${LING}.perl |

                 #$PROGSDIR/parserFromDPG.perl |
                 $PROGSDIR/subs.perl |$PROGSDIR/preps.perl |
                # $PROGSDIR/subsDeps.sh |
                 #$PROGSDIR/contextos_fromDeps_filtering.perl  $INPUTDIR/words-mw-$LING |
                 $PROGSDIR/contextos_fromDeps_filtering.perl  $INPUTDIR/unconstrained/new-en.txt
                 awk -v T=$TAG '{print $1, $2"\#"T, $3" "T}'> $TMPDIR/__tmp
 
cat $TMPDIR/__tmp |gzip -c > $OUTPUTFILE

echo "Criado ficheiro de frequencias sem filtrar"




#rm $TMPDIR/__*
#rm $TMPDIR/*

