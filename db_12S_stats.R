library(tidyverse)
# grep ">" db_12S.fasta | awk '{print $1,$3,$4,$5}' FS='|' OFS=';' | sed 's/>//g' | sed 's/ ; /;/g' > db_12S_stats.csv
setwd('~/Dropbox/WABI/Projects/Snoeijs/12S/')
soi <- read.table('species_of_interest.txt', col.names = 'species', sep = '^')
stats <- read.table('db_12S_stats.csv', sep = ';', col.names = c('id', 'family', 'genus', 'species'))

missing <- soi[!(soi$species %in% stats$species),]

counts <- stats %>% 
  group_by(species) %>% 
  summarise(n_seq = n()) %>%
  add_row(species=missing, n_seq = 0) %>%
  arrange(species)

urls <- paste0('<a href="https://fishbase.se/summary/', str_replace(counts$species,' ', '-'),'.html">', str_replace(counts$species, ' ', '_'), '</a>')
