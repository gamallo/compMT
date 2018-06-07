
#/bin/bash

DIR=`pwd`


PROGSDIR=$DIR/progs
TMPDIR=$DIR/tmp
INPUTDIR=$DIR/freq
OUTPUTDIR=$DIR/stored
##STORE-RETRIEVE:


zcat $INPUTDIR/freq_templates_test-en-es_Filtrado_V.txt.gz | sed "s/\&/\//g" | $PROGSDIR/store.perl "s" "E"  $OUTPUTDIR/verb-en.st &
a=$!

zcat $INPUTDIR/freq_templates_test-en-es_Filtrado_V.txt.gz | sed "s/\&/\//g" | $PROGSDIR/store.perl "t" "S"  $OUTPUTDIR/verb-es.st &
b=$!

zcat $INPUTDIR/freq_templates_test-en-es_Filtrado_N.txt.gz | sed "s/\&/\//g" | $PROGSDIR/store.perl "s" "E"  $OUTPUTDIR/noun-en.st &
c=$!

zcat $INPUTDIR/freq_templates_test-en-es_Filtrado_N.txt.gz | sed "s/\&/\//g" | $PROGSDIR/store.perl "t" "S"  $OUTPUTDIR/noun-es.st &
d=$!

wait $a $b $c $d
