#/bin/bash

#./run_freqs.sh test en E

DIR=`pwd`


PROGSDIR=$DIR/progs
TMPDIR=$DIR/tmp
INPUTDIR=$DIR/parsed
OUTPUTDIR=$DIR/freq


#####PARAMETERS##########

PREFFIX=$1
LING=$2
TAG=$3

#TH=50
TH=20

########################

#input:

INPUTFILE=${INPUTDIR}/"parse_"${PREFFIX}"-"${LING}.txt.gz ;

#outputs:

OUTPUTFILE=$OUTPUTDIR"/freq_"${PREFFIX}"-"$LING".txt.gz"


zcat $INPUTFILE | $PROGSDIR/filtering_words_from_dp.perl $TH > tmp/words-$LING

zcat $INPUTFILE | $PROGSDIR/contextos_fromDeps_filtering_PARALLEL_4.perl tmp/words-$LING $LING

cat temporal_$LING* >> temporal_$LING

cat temporal_$LING | awk -v T=$TAG '{print $1, $2"#"T, $3" "T}'> $TMPDIR/__tmp$LING
rm temporal_$LING*

# rm $TMPDIR/__tmp
# touch $TMPDIR/__tmp
# for filename in $TMPDIR/frecuencia_ivan_*; do
#     cat $filename | awk -v T=$TAG '{print $1, $2"#"T, $3" "T}' >> $TMPDIR/__tmp
# done

 echo "Inicio zip FREQS"
pigz -f -k $TMPDIR/__tmp$LING
mv $TMPDIR/__tmp$LING.gz $OUTPUTFILE

echo "Criado ficheiro de frequencias sem filtrar"


#rm $TMPDIR/frecuencia_ivan_*
#rm $TMPDIR/__*
#rm $TMPDIR/*
