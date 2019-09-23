SHELL=/bin/bash

PIPELINE_DIR := $(shell realpath --relative-to=. $(dir $(lastword $(MAKEFILE_LIST))))

default:: all

all::

# distclean::
# 	rm -rf data

# ------------------------------------------------------------------------

all:: data/genome/genome.fna

data/assembly :
	${PIPELINE_DIR}/download-assembly \
		${ASSEMBLY_ACCESSION} data/assembly
data/genome/genome.fna : data/assembly
	${PIPELINE_DIR}/demux-genome ${MOLECULE_NAMES} \
		data/assembly data/genome

# ------------------------------------------------------------------------

all:: data/sample1.mgf data/sample2.mgf data/sample3.mgf

data/sample1.mgf : $(SAMPLE1_MGF)
	mkdir -p data
	pigz -dc $^ > $@

data/sample2.mgf : $(SAMPLE2_MGF)
	mkdir -p data
	pigz -dc $^ > $@

data/sample3.mgf : $(SAMPLE3_MGF)
	mkdir -p data
	pigz -dc $^ > $@

# ------------------------------------------------------------------------

all:: data/6ft.faa data/6ft.gff

data/6ft.faa data/6ft.gff : data/genome/genome.fna
	${PIPELINE_DIR}/make-db-6ft \
		-f data/6ft.faa -g data/6ft.gff -s $$[3*${ORF_MIN_LENGTH}] \
		data/genome/genome.fna

# ------------------------------------------------------------------------

all:: data/db.fasta data/db.gff

data/contams.faa : ${CONTAMINANTS_DB}
	cat ${CONTAMINANTS_DB} | tr -d '\015' > data/contams.faa
data/contams.gff : data/contams.faa
	cat data/contams.faa | ${PIPELINE_DIR}/make-contam-gff.pl > data/contams.gff

data/db.fasta : data/6ft.faa data/contams.faa
	cat $^ > $@
data/db.gff : data/6ft.gff data/contams.gff
	cat $^ > $@


# ------------------------------------------------------------------------

all:: data/sample1.pin data/sample2.pin data/sample3.pin

data/comet.params : ${COMET_PARAMS}
	cat ${COMET_PARAMS} \
		| sed -e 's|DB_FILE|db.fasta|' \
	      	> data/comet.params

data/sample1.pep.xml data/sample1.pin : data/sample1.mgf data/db.fasta data/comet.params ${PIPELINE_DIR}/packages.yaml
	( cd data ; ../${PIPELINE_DIR}/howto -f ../${PIPELINE_DIR}/packages.yaml comet.exe sample1.mgf )
data/sample2.pep.xml data/sample2.pin : data/sample2.mgf data/db.fasta data/comet.params ${PIPELINE_DIR}/packages.yaml
	( cd data ; ../${PIPELINE_DIR}/howto -f ../${PIPELINE_DIR}/packages.yaml comet.exe sample2.mgf )
data/sample3.pep.xml data/sample3.pin : data/sample3.mgf data/db.fasta data/comet.params ${PIPELINE_DIR}/packages.yaml
	( cd data ; ../${PIPELINE_DIR}/howto -f ../${PIPELINE_DIR}/packages.yaml comet.exe sample3.mgf )

# ------------------------------------------------------------------------

all:: data/sample1.target_peptide_results.tsv data/sample2.target_peptide_results.tsv data/sample3.target_peptide_results.tsv

data/sample1.target_peptide_results.tsv : data/sample1.pin data/db.fasta ${PIPELINE_DIR}/packages.yaml
	${PIPELINE_DIR}/howto \
		-f ${PIPELINE_DIR}/packages.yaml \
		percolator data/sample1.pin \
		--picked-protein data/db.fasta \
		--protein-decoy-pattern DECOY_ \
		--protein-report-fragments \
		--protein-report-duplicates \
		--decoy-results-psms data/sample1.decoy_psm_results.tsv \
		--decoy-results-peptides data/sample1.decoy_peptide_results.tsv\
		--decoy-results-proteins data/sample1.decoy_protein_results.tsv \
		--results-psms data/sample1.target_psm_results.tsv \
		--results-peptides data/sample1.target_peptide_results.tsv \
		--results-proteins data/sample1.target_protein_results.tsv

data/sample2.target_peptide_results.tsv : data/sample2.pin data/db.fasta ${PIPELINE_DIR}/packages.yaml
	${PIPELINE_DIR}/howto \
		-f ${PIPELINE_DIR}/packages.yaml \
		percolator data/sample2.pin \
		--picked-protein data/db.fasta \
		--protein-decoy-pattern DECOY_ \
		--protein-report-fragments \
		--protein-report-duplicates \
		--decoy-results-psms data/sample2.decoy_psm_results.tsv \
		--decoy-results-peptides data/sample2.decoy_peptide_results.tsv\
		--decoy-results-proteins data/sample2.decoy_protein_results.tsv \
		--results-psms data/sample2.target_psm_results.tsv \
		--results-peptides data/sample2.target_peptide_results.tsv \
		--results-proteins data/sample2.target_protein_results.tsv

data/sample3.target_peptide_results.tsv : data/sample3.pin data/db.fasta ${PIPELINE_DIR}/packages.yaml
	${PIPELINE_DIR}/howto \
		-f ${PIPELINE_DIR}/packages.yaml \
		percolator data/sample3.pin \
		--picked-protein data/db.fasta \
		--protein-decoy-pattern DECOY_ \
		--protein-report-fragments \
		--protein-report-duplicates \
		--decoy-results-psms data/sample3.decoy_psm_results.tsv \
		--decoy-results-peptides data/sample3.decoy_peptide_results.tsv\
		--decoy-results-proteins data/sample3.decoy_protein_results.tsv \
		--results-psms data/sample3.target_psm_results.tsv \
		--results-peptides data/sample3.target_peptide_results.tsv \
		--results-proteins data/sample3.target_protein_results.tsv

# ------------------------------------------------------------------------

all:: data/pg-search-results.gff
data/pg-search-results.gff : data/db.fasta data/db.gff \
		data/sample1.target_peptide_results.tsv \
		data/sample2.target_peptide_results.tsv \
		data/sample3.target_peptide_results.tsv \
		${PIPELINE_DIR}/percs2gff
	${PIPELINE_DIR}/percs2gff ${PERCS2GFF_ARGS} \
	    -r data/perc_report.txt \
	    -o data/pg-search-results.gff \
	    data/db.fasta data/db.gff \
	    data/sample1.target_peptide_results.tsv \
	    data/sample2.target_peptide_results.tsv \
	    data/sample3.target_peptide_results.tsv


# ------------------------------------------------------------------------


