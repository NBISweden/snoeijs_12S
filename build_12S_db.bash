#!/bin/bash

base_dir=$(pwd)
db_url="ftp.ncbi.nlm.nih.gov/genbank"
db_dir="genbank"
db_prefix="gbvrt"

# Download genbank if necessary
rsync --partial --progress -avz rsync://${db_url}/GB_Release_Number .
file_list=$(rsync --list-only rsync://${db_url}/${db_prefix}\* | grep ".gz" | awk -v url="${db_url}/" '{print "ftp://"url $NF}')

for file in ${file_list[@]}
	do
	echo "Downloading: ${file}" 
	wget ${file}
	filename="${file##*/}"
	python3 gb2fasta.py ${filename} >> db_12S.fasta 
	rm ${filename}
	done

