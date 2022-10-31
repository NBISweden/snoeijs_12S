# snoeijs_12S

The 12S part of Snoeijs-Leijonmalm_2205 project.

## Synopsis
Create a 12S database of marine CAO species from GenBank gbvrt* sequences. 

## Architecture

1. `gb2fasta.py` is the main script that takes requires `species_of_interest.txt` file of the following format:
```
Gonatus fabricii
Arctogadus glacialis
Boreogadus saida
Gadus morhua
Melanogrammus aeglefinus
Sebastes mentella
Gadus chalcogrammus
Gadus macrocephalus
Mallotus villosus
Clupea harengus
...
```
The file contains species that are of our interest and will be included in the database. 
The only variable argument to the script is a name of the GenBank file. When ran, the script takes a genbank sequence by sequence, 
checks whether "12S" keyword is present in the sequence description and if so it also checks whether species annotation exists. If species annotation exists and matches one of the species of interests, the sequence is converted to fasta format and printed. All sequences with odd species annotations are saed in `error.log` and additionally family, genus and species information is saved in `species_families.txt` like this:
```
Pleuronectidae; Reinhardtius; Reinhardtius hippoglossoides
Pleuronectidae; Reinhardtius; Reinhardtius hippoglossoides
Pleuronectidae; Reinhardtius; Reinhardtius hippoglossoides
Gadidae; Gadus; Gadus chalcogrammus
...
```

2. `build_12S_db.bash` script downloads a list of all `gbvrt*` (can be modified in the parameters section) files on GenBank FTP server, downloads file by file and processes it with `gb2fasta.py`. After being processed, the original GenBank file is removed. All sequences are stored in a fasta file (by output redirection mechanism).

3. The `db_12S_stats.Rmd` file contains RMarkdown to generate a report about the created database. Fish pictures come from the Internet and they may be under some license so do not use them freely in a publication without checking this!

You can see rendered report [here](https://htmlpreview.github.io/?https://www.dropbox.com/s/en4m8s7qasp0g0m/db_12S_stats.html?dl=1).
