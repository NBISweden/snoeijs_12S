TARGET = "12S"
NCBI_QUERY = ""
SOURCE = "mitofish"
RUN_PCR = True
FWD="GTCGGTAAAACTCGTGCCAGC" # 5' -- 3'
REV="CATAGTGGGGTATCTAATCCCAGTTTG" # 5' -- 3'

assign_tax_input = list()
if RUN_PCR == True:
	assign_tax_input.append(TARGET + "_" + SOURCE + "_merged.fasta")
else:
	assign_tax_input.append(TARGET + "_" + SOURCE + ".fasta") 

container: 
	"docker://quiestrho/crabs:1.0.0"
	
rule all:
	input:
		TARGET + "_" + SOURCE + "_clean_completeness.txt",
		TARGET + "_" + SOURCE + "_clean.fasta"

rule download_taxonomy:
	input:
	output: 
		o1 = "nucl_gb.accession2taxid"
	shell:
		"""
		crabs db_download --source taxonomy
		"""

rule download_database:
	input: rules.download_taxonomy.output.o1
	output:
		o1 = TARGET + "_" + SOURCE + ".fasta"
	params:
		out = TARGET + "_" + SOURCE + ".fasta",
		query = "\'12S[All Fields] AND (\"50\"[SLEN] : \"5000\"[SLEN])\'",
		source = SOURCE,
		email = "anonymous@anonymous.org",
		batch = 5000,
		keep_original = "no"
	shell:
		"""
		crabs db_download \
				--source {params.source} \
				--database nucleotide \
				--query {params.query} \
				--output {params.out} \
				--batchsize {params.batch} \
				--email {params.email} \
				--keep_original {params.keep_original}
		"""

rule run_virtual_pcr:
	input: 
		i1 = rules.download_database.output.o1,
	output: 
		o1 = TARGET + "_" + SOURCE + "_vpcr.fasta"
	params:
		fwd = FWD,
		rev = REV,
		error = 4.5
	shell:
		"""
		crabs insilico_pcr \
			--input {input.i1} \
			--output {output.o1} \
			--fwd {params.fwd} \
			--rev {params.rev} \
			--error {params.error}
		"""

rule run_pga:
	input: 
		i1 = rules.download_database.output.o1,
		i2 = rules.run_virtual_pcr.output.o1,
	output:
		o1 = TARGET + "_" + SOURCE + "_pga.fasta"
	params:
		fwd = FWD,
		rev = REV,
		speed = "medium",
		perc_identity = 0.95,
		coverage = 0.95,
		filter_method = "strict",
	shell:
		"""
		crabs pga \
			--input {input.i1} \
			--output {output.o1} \
			--database {input.i2} \
			--fwd {params.fwd} \
			--rev {params.rev} \
			--speed {params.speed} \
			--percid {params.perc_identity} \
			--coverage {params.coverage} \
			--filter_method {params.method}
		"""

rule merge_vpcr_pwa:
	input:
		i1 = rules.run_virtual_pcr.output.o1,
		i2 = rules.run_pga.output.o1
	output:
		o1 = TARGET + "_" + SOURCE + "_merged.fasta"
	params:
		uniq = "yes",
	shell:
		"""
		crabs db_merge \
			--output {output.o1} \
			--uniq {params.uniq} \
			--input {input.i1} {input.i2}
		"""	

rule assign_taxonomy:
	input:
		i1 = assign_tax_input
	output:
		o1 = TARGET + "_" + SOURCE + "_assigned_taxa.tsv"
	params:
		missing = TARGET + "_" + SOURCE + "_missing_taxa.tsv"
	shell:
		"""
		crabs assign_tax \
			--input {input.i1}
			--output {output.o1} \
			--acc2tax {rules.download_taxonomy.output.o1} \
			--taxid nodes.dmp \
			--name names.dmp \
			--missing {params.missing}
		"""
rule dereplicate:
	input:
		i1 = rules.assign_taxonomy.output.o1,
	output:
		o1 = TARGET + "_" + SOURCE + "_derep.tsv",
	params:
		method = "uniq_species",
	shell:
		"""
	 	dereplicate \
			--input {input.i1}  \
			--output {output.o1} \
			--method {params.method}
		"""

rule sequence_cleanup:
	input:
		i1 = rules.dereplicate.output.o1,
	output:
		o1 = TARGET + "_" + SOURCE + "_clean.tsv"
	params:
		minlen = 150,
		maxlen = 300,
		maxns = 2,
		enviro = "yes",
		species = "yes"
	shell:
		"""
		crabs seq_cleanup \
			--input {input.i1} \
			--output {output.o1} \
			--minlen {params.minlen} \
			--maxlen {params.maxlen} \
			--maxns {params.maxns} \
			--enviro {params.enviro} \
			--species {params.species}
		"""

rule visualize:
	input:
		i1 = rules.sequence_cleanup.output.o1,
		i2 = "species_of_interest.txt"
	output:
		o1 = TARGET + "_" + SOURCE + "_clean_completeness.txt",
	params:
		method = "db_completeness",
		taxid = "nodes.dmp",
		name = "names.dmp",
	shell:
		"""
		crabs visualization \
			--input {input.i1} \
			--output {output.o1} \
			--species {input.i2} \
			--method = {params.method} \
			--taxid {params.taxid} \ 
			--name {params.name}
		"""

rule convert_to_fasta:
	input: 
		i1 = rules.sequence_cleanup.output.o1,
	output:
		o1 = TARGET + "_" + SOURCE + "_clean.fasta"
	params:
		format = "sintax"
	shell:
		"""
		crabs tax_format \
			--input {input.i1} \
			--output {output.o1} \
			--format {params.format}
		"""
