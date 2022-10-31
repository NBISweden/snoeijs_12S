import gzip
import sys
from Bio import SeqIO
from ete3 import NCBITaxa
ncbi = NCBITaxa()
#ncbi.update_taxonomy_database()

file1 = open("species_families.txt", "a+") 
file2 = open("error.log", "a+")
file3 = "species_of_interest.txt"

cnt = 0

def validate_record(record):
	is_valid = True
	if ('db_xref') not in record.features[0].qualifiers.keys():
		is_valid = False
	return(is_valid)

# Read species of interest into a list
with open(file3) as file:
    soi = file.readlines()
    soi = [line.rstrip() for line in soi]

#print("Species of interest: ")
#print(soi)

with gzip.open(sys.argv[1], "rt") as handle:
	for record in SeqIO.parse(handle, "genbank"):
		#print(record.annotations)
		descr = record.description
		if "12S" in descr and validate_record(record):
			id = record.id
			org = record.annotations['organism'].strip()
			#print(str(record.seq))
			taxid = str(record.features[0].qualifiers['db_xref'][0]).replace('taxon:', '')
			try:
				lineage = ncbi.get_lineage(taxid)
				ranks = ncbi.get_rank(lineage)
				ranks2 = dict([(value, key) for key, value in ranks.items()])
				try:
					family = next(iter(ncbi.get_taxid_translator([ranks2['family']]).values()))
				except KeyError:
					family = '?'
				try:
					genus = next(iter(ncbi.get_taxid_translator([ranks2['genus']]).values()))
				except KeyError:
					genus = '?'
				try:
					species = next(iter(ncbi.get_taxid_translator([ranks2['species']]).values()))
				except KeyError:
					species = '?'
				if any(spc in species for spc in soi):
					print("> " + id + ' | ' + descr + ' | ' + family + ' | ' + genus + ' | ' + species)
					print(str(record.seq))
					file1.write(family.strip() + '; ' + genus.strip() + '; ' + species.strip() + '\n')
			except:
				#print('Unspecified error. Skipping sequence ' + id)
				file2.write(id.strip() + '\n')
			cnt = cnt + 1
#		if cnt >= 2:
#			break
file1.close()
file2.close()
