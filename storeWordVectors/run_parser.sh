#!/bin/bash

##Example:
#./run_parser.sh test en

DIR=`pwd`
#echo $DIR

PROGSDIR=$DIR/progs
TMPDIR=$DIR/tmp
INPUTDIR=$DIR/tagged
OUTPUTDIR=$DIR/parsed


#####PARAMETERS##########

PREFFIX=$1
LING=$2

########################


#input:

INPUTFILE=${INPUTDIR}/${PREFFIX}"-"${LING}.txt.gz ;

#outputs:

OUTPUTFILE=$OUTPUTDIR"/parse_"${PREFFIX}"-"$LING".txt.gz"

zcat $INPUTFILE |$PROGSDIR/AdapterFreeling-${LING}.perl |

                 $PROGSDIR/parser-${LING}.perl |
                 $PROGSDIR/subs.perl |$PROGSDIR/preps.perl  > $TMPDIR/__tmp$LING


cat $TMPDIR/__tmp$LING |gzip -c > $OUTPUTFILE



#rm $TMPDIR/__*
#rm $TMPDIR/*
