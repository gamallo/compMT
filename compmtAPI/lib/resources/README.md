# Dataset PhrasalVerbs2Spanish

## Description
This dataset was built to evaluate bilingual paraphrasing systems in restricted syntactic domains. It consists of 1119 English sentences with 665 different phrasal verbs, and 1,837 Spanish translations (i.e. paraphrases) with 1,241 different Spanish verbs (including single and multiword verbs). The 665 English phrasal verbs are all very ambiguous: their average Spanish translations per verb in the bilingual lexicon is 5.25.

Each row consists of an English sentence with a phrasal verb (first column), the Spanish translations or paraphrases (second column), and the Spanish verb (or phrasal verb) used to translate the English phrasal verb (third column).

All examples contain simple constructions: intransitive or transitive constructions merely including noun phrases, verb phrases, adjectives and prepositional phrases. By contrast, coordination or embedding structures such as relative clauses or completives are not allowed. As distributional-based paraphrasing is focused on the meaning of lexical units, grammatical and encyclopedic units such as pronouns, conjunctions, and proper nouns are also not allowed.
The PhrasalVerbsToSpanish dataset is actually focused on the task of translating the phrasal verb of an English sentence by disambiguating its sense using the meaning of the context words. So, contextualization is a key concept in this task.
