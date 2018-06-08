# Compositional Machine Translation (compMT)

## Requirements

* Dancer2: ```http://perldancer.org/```

* Resources files (hash tables) built from corpora. Download the resource files from the following link:

```
htpp:fegalaz.usc.es/~gamallo/stored.tgz
```

And copy them in `storeWordVectors/stored`

## Resources included in the repository

* Golden dataset for evaluation: 1119 english sentences containing phrasal verbs, with their Spanish translations, including the corresponding Spanish verb are in: `compMT/lib/resources/golden-en-es.csv`

* Bilingual dictionary: a English-Spanish dictionary, including more than 3K phrasal verbs is in `compMT/lib/compMT/dicos/dictionary-en-es.txt`
