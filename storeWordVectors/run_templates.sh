#/bin/bash

DIR=`pwd`


PROGSDIR=$DIR/progs
TMPDIR=$DIR/tmp
INPUTDIR=$DIR/freq
SEEDDIR=$DIR/seeds
OUTPUTDIR=$DIR/freq


##Parameters####
#for instance: run_templates.sh test en es E S 20

PREFFIX=$1 ##base name of the corpus...
LING1=$2 #en, gl,...
LING2=$3
TAG1=$4 # E, G,...
TAG2=$5

##min freq
TH=$6

MIN=2
MAX=10000000
########################


#input:

INPUTFILE=${INPUTDIR}"/freq_"${PREFFIX}"-"* ;

SEEDFILE=${SEEDDIR}"/format_seedTemplates_"${LING1}"-"${LING2}".txt"

zcat $INPUTFILE > $TMPDIR/__tmp



#output:
OUTPUTFILE=$OUTPUTDIR"/freq_templates_"${PREFFIX}"-"${LING1}"-"${LING2}".txt.gz"

#OUTPUTFILEFILTRADO=$OUTPUTDIR"/freq_"$LEX"_templates_"${SUFFIX}"-"${LING1}"-"${LING2}"_Filtrado.txt.gz"
OUTPUTFILEFILTRADO_N=$OUTPUTDIR"/freq_templates_"${PREFFIX}"-"${LING1}"-"${LING2}"_Filtrado_N.txt.gz"
OUTPUTFILEFILTRADO_A=$OUTPUTDIR"/freq_templates_"${PREFFIX}"-"${LING1}"-"${LING2}"_Filtrado_A.txt.gz"
OUTPUTFILEFILTRADO_V=$OUTPUTDIR"/freq_templates_"${PREFFIX}"-"${LING1}"-"${LING2}"_Filtrado_V.txt.gz"
OUTPUTFILEFILTRADO_R=$OUTPUTDIR"/freq_templates_"${PREFFIX}"-"${LING1}"-"${LING2}"_Filtrado_R.txt.gz"



echo "criar ficheiro de templates"
cat $TMPDIR/__tmp |$PROGSDIR/selectTemplates.perl $SEEDFILE $TAG1 $TAG2  | gzip -c > $OUTPUTFILE


##filtrar e separar ficheiros de contextos por categorias:
echo "filtering 1 (baseline)..."
zcat $OUTPUTFILE  | $PROGSDIR/filtering_templates.perl > tmp/templates
zcat $OUTPUTFILE  | $PROGSDIR/identificarTemplates_filtering.perl $MIN $MAX $TH  tmp/templates  > $TMPDIR/__filtrado1

echo "filtering 2 (Bordag strategy..."
##calcular a Fronteira de frequencias:
#Boundary=`cat $TMPDIR/__filtrado1  | $PROGSDIR/Boundary.perl`
Boundary=500
cat $TMPDIR/__filtrado1 | $PROGSDIR/loglike_new.perl  $TMPDIR/__filtrado1 > $TMPDIR/__filtrado2

echo "Criado ficheiro de frequencias sem filtrar"

echo "separar N"
#N=20
#WC=`wc -l tmp/__filtrado2`
#let PART=279472978/$N
#let PART=$WC/$N
#echo "partitions: $PART"

cat $TMPDIR/__filtrado2 |$PROGSDIR/separarN_alph.perl

cat $TMPDIR/__filtrado2 |$PROGSDIR/separarA.perl > tmp/__separadoA
cat $TMPDIR/__filtrado2 |$PROGSDIR/separarV.perl > tmp/__separadoV
cat $TMPDIR/__filtrado2 |$PROGSDIR/separarR.perl > tmp/__separadoR


for j in $TMPDIR/__separadoN_*; do
  BASE=`basename $j`;
  echo $j
  cat $j | $PROGSDIR/bordag_new.perl $Boundary  > $TMPDIR/__filtradoN_$BASE
done

cat $TMPDIR/__filtradoN_*  > $TMPDIR/__filtradoN
cat $TMPDIR/__separadoA | $PROGSDIR/bordag.perl $Boundary  > $TMPDIR/__filtradoA
cat $TMPDIR/__separadoV | $PROGSDIR/bordag_new.perl $Boundary  > $TMPDIR/__filtradoV
cat $TMPDIR/__separadoR | $PROGSDIR/bordag.perl $Boundary  > $TMPDIR/__filtradoR


cat $TMPDIR/__filtradoN | gzip -c > $OUTPUTFILEFILTRADO_N
cat $TMPDIR/__filtradoA | gzip -c > $OUTPUTFILEFILTRADO_A
cat $TMPDIR/__filtradoV | gzip -c > $OUTPUTFILEFILTRADO_V
cat $TMPDIR/__filtradoR | gzip -c > $OUTPUTFILEFILTRADO_R




#rm $TMPDIR/__filtrado1
#rm $TMPDIR/__filtrado2
#rm $TMPDIR/__tmp
