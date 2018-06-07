#!/bin/bash

# example: ./run_mwe.sh en

echo "Recollida de datos para analise de multiwords"

DIR=`pwd`
PROGS=${DIR}/progs
MWE=${DIR}/mwe
TAGGED=${DIR}/tagged
PHRASAL_V=${MWE}/phrasal_verbs.txt
OUTPUTDIR=${DIR}/parsed
PREFFIX=test

#####PARAMETERS##########

LING=$1

########################

INPUTFILE="${TAGGED}/mw-${LING}.txt"
OUTPUTFILE="${OUTPUTDIR}/parse_mw-$LING.txt.gz"

grep -P "\t.*[a-z]*\s[a-z]*.*" ${PHRASAL_V} > .phrasal_verbs.tmp
mv .phrasal_verbs.tmp ${PHRASAL_V}

if [ "${LING}" == "en" ]; then
    field=1
elif [ "${LING}" == "es" ]; then
    field=2
else
    echo "Language code '${LING}' is not valid"
    exit 1
fi

cat ${PHRASAL_V} | sed "s/\\r//g" | sed "s/ /@/g" |cut -f ${field} |sed "s/$/_VERB/" |  sed -n '/@/p' |
sed "s/@@_/@_/" |sed "s/@_/_/" |grep "@"  > ${MWE}/words-mw-${LING}

# tagger
zcat ${TAGGED}/${PREFFIX}-${LING}.txt.gz | ${PROGS}/select_mw-${LING}.perl ${MWE}/words-mw-${LING} > ${TAGGED}/mw2-${LING}.txt

# parser
cat ${TAGGED}/mw-${LING}.txt |${PROGS}/limparTexto.x | /home/gamallo/Linguakit-master/linguakit_tunned2.perl dep $LING  | ${PROGS}/subs.perl | ${PROGS}/preps.perl | gzip -c > ${OUTPUTFILE} 


#cat ${TAGGED}/mw-${LING}.txt | ${PROGS}/AdapterFreeling-${LING}.perl | ${PROGS}/parser-${LING}.perl | ${PROGS}/subs.perl | ${PROGS}/preps.perl | gzip -c > ${OUTPUTFILE}

echo "fin da recollida"
