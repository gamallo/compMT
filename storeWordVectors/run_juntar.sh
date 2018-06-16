#!/bin/bash

##Example:
#./run_parser.sh test en

DIR=`pwd`
#echo $DIR

PROGSDIR=$DIR/progs
TMPDIR=$DIR/tmp
INPUTDIR=$DIR/freq
OUTPUTDIR=$DIR/freq


#####PARAMETERS##########

PREFFIX1=$1
PREFFIX2=$2
LING=$3
TAG=$4

TH=1
########################


#input:

INPUTFILE1=${INPUTDIR}/freq_${PREFFIX1}"-"${LING}.txt.gz ;
INPUTFILE2=${INPUTDIR}/freq_${PREFFIX2}"-"${LING}.txt.gz ;
#outputs:

OUTPUTFILE=$OUTPUTDIR"/freq_"${PREFFIX1}"-"$LING".txt.gz"

zcat $INPUTFILE1 $INPUTFILE2  |$PROGSDIR/juntarFreqs.perl $TH $TAG > $TMPDIR/__tmp
rm $INPUTFILE1

cat $TMPDIR/__tmp |gzip -c > $OUTPUTFILE

#rm $TMPDIR/__*
#rm $TMPDIR/*
