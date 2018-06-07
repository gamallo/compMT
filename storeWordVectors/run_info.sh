## Cousas a melhorar em relaçom a variáveis internas:
###dentro de run_freqs_parallel.sh, hai que sacar fora como parametro a variavel $th: th=20 para freq_mwe e th=50 para run_test
###sacar fora a variavel $th de select_templates (por defeito th=50): provar com valores inferiores para ter mais contextos/templates.

###sequencialidade dos processos:

##1. tagging dos textos de entrada com Linguakit-master
##de ./corpus a ./tagged (falta fazer um script tipo run_tagger.sh)

##2. Multipalavras (independente):
#./run_mw_new.sh mw es
#./run_mw_new.sh mw en

##./run_freqs_parallel.sh mw en E &
#c=$!
##./run_freqs_parallel.sh mw es S &
#d=$!


##3. Parsing test:
#./run_parser.sh test es &
#a=$!
#./run_parser.sh test en &
#b=$!

wait $a $b

##4. Criar freq do ficheiro principal (test)
#./run_freqs_parallel.sh test en E &
#c=$!
#./run_freqs_parallel.sh test es S &
#d=$!

###5. Juntar todos os freqs:
##juntarFreqs.perl 1 S                                                                                                                                                          
##juntarFreqs.perl 1 E 

wait $c $d

##6. Criar seeds:
#./run_seeds.sh test en es E S

##7.Criar freqs bilingues:
#./run_templates.sh test en es E S 10

##8. Criar st:
#sh run_store_parallel2.sh
