#/bin/bash

###Sequence of processes to generate the STs files, which are the input of compMT:

#Requirements:
## you need to create two tagged files into folder ./tagged. For instance:
## test-en.txt.gz and test-es.txt.gz
## You can use LinguaKit or FreeLing


echo "1. Generating 'freq' files of multiwords (including phrasal verbs)"
./run_mw_new.sh es
./run_mw_new.sh en

./run_freqs_parallel.sh mw en E &
c=$!
./run_freqs_parallel.sh mw es S &
d=$!


echo "2. Parsing tagged files:"
./run_parser.sh test es &
a=$!
./run_parser.sh test en &
b=$!

wait $a $b

echo "3. Generating 'freq' files from parsed files"
./run_freqs_parallel.sh test en E &
e=$!
./run_freqs_parallel.sh test es S &
f=$!

wait $e $f

echo "4. merging freq files"
##juntar.sh
sh run_juntar.sh test mw en E
sh run_juntar.sh test mw es S


echo "5. Building seeds:"
./run_seeds.sh test en es E S

echo "6. building bilingual freqs (templates)"
./run_templates.sh test en es E S 10

echo "7. Creating ST files:"
sh run_store_parallel2.sh

mv ./stored/* ../compmtAPI/lib/resources/.

rm tmp/*
echo "END OF THE STORING PROCESS"
