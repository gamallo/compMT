# Compositional Machine Translation (compMT)

## Requirements

* Dancer2: ```http://perldancer.org/```

* Resources files (hash tables) built from corpora. Download the files in ST format with Wikipedia models, from this [link](https://nubeusc-my.sharepoint.com/:u:/g/personal/pablo_gamallo_usc_es/EWPYeTFZCiZEnMl1HVQzK3cBJEQQ6KEId70PBh5xWVl30w?e=O1jfq2), and copy them in `./lib/resources/.`


* Change the PATH of the main folders (lib, parser, dicos, stFiles) in config.yml file

## Resources included in the repository

* Golden dataset for evaluation: 1119 english sentences containing phrasal verbs, with their Spanish translations, including the corresponding Spanish verb are in: `compMT/lib/resources/golden-en-es.csv`

* Bilingual dictionary: a English-Spanish dictionary, including more than 3K phrasal verbs is in `compMT/lib/compMT/dicos/dictionary-en-es.txt`

## How to use
* Mount the Dancer service:
```./compmtAPI/main.perl```

* Translate a sentence:

```curl "http://localhost:4000/translate/the%20man%20blew%20off%20the%20party"```

* Validate the model using the 1119 examples of the gold standard:

```curl "http://localhost:4000/validate/golden"```
This creates the validation file: `./lib/resources/validation/golden_validated`


