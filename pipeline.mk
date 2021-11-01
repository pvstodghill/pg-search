SHELL=/bin/bash

ifeq ($(origin DATA), undefined)
DATA = data
endif


# PIPELINE_DIR := $(shell realpath --relative-to=. $(dir $(lastword $(MAKEFILE_LIST))))
# PIPELINE_DIRx := $(shell mkdir -p ${DATA} ; realpath --relative-to=${DATA} $(dir $(lastword $(MAKEFILE_LIST))))
PIPELINE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PIPELINE_DIRx := ${PIPELINE_DIR}

default:: all

all::
	@mkdir -p ${DATA}

# distclean::
# 	rm -rf ${DATA}

# ------------------------------------------------------------------------

all:: ${DATA}/genome/genome.fna

${DATA}/assembly :
	${PIPELINE_DIR}/download-assembly \
		${ASSEMBLY_ACCESSION} ${DATA}/assembly
${DATA}/genome/genome.fna : ${DATA}/assembly
	${PIPELINE_DIR}/demux-genome ${MOLECULE_NAMES} \
		${DATA}/assembly ${DATA}/genome

# ------------------------------------------------------------------------

all:: ${DATA}/sample1.mgf ${DATA}/sample2.mgf ${DATA}/sample3.mgf

${DATA}/sample1.mgf : $(SAMPLE1_MGF)
	mkdir -p ${DATA}
	pigz -dc $^ > $@

${DATA}/sample2.mgf : $(SAMPLE2_MGF)
	mkdir -p ${DATA}
	pigz -dc $^ > $@

${DATA}/sample3.mgf : $(SAMPLE3_MGF)
	mkdir -p ${DATA}
	pigz -dc $^ > $@

# ------------------------------------------------------------------------

all:: ${DATA}/6ft.faa ${DATA}/6ft.gff

${DATA}/6ft.faa ${DATA}/6ft.gff : ${DATA}/genome/genome.fna
	${PIPELINE_DIR}/make-db-6ft \
		-f ${DATA}/6ft.faa -g ${DATA}/6ft.gff -s $$[3*${ORF_MIN_LENGTH}] \
		${DATA}/genome/genome.fna

# ------------------------------------------------------------------------

all:: ${DATA}/db.fasta ${DATA}/db.gff

${DATA}/contams.faa : ${CONTAMINANTS_DB}
	cat ${CONTAMINANTS_DB} | tr -d '\015' > ${DATA}/contams.faa
${DATA}/contams.gff : ${DATA}/contams.faa
	cat ${DATA}/contams.faa | ${PIPELINE_DIR}/make-contam-gff.pl > ${DATA}/contams.gff

${DATA}/db.fasta : ${DATA}/6ft.faa ${DATA}/contams.faa
	cat $^ > $@
${DATA}/db.gff : ${DATA}/6ft.gff ${DATA}/contams.gff
	cat $^ > $@


# ------------------------------------------------------------------------

all:: ${DATA}/sample1.pin ${DATA}/sample2.pin ${DATA}/sample3.pin

${DATA}/comet.params : ${COMET_PARAMS}
	cat ${COMET_PARAMS} \
		| sed -e 's|DB_FILE|db.fasta|' \
	      	> ${DATA}/comet.params

${DATA}/sample1.pep.xml ${DATA}/sample1.pin : ${DATA}/sample1.mgf ${DATA}/db.fasta ${DATA}/comet.params ${PIPELINE_DIR}/packages.yaml
	( cd ${DATA} ; ${PIPELINE_DIRx}/howto -f ${PIPELINE_DIRx}/packages.yaml comet.exe sample1.mgf )
${DATA}/sample2.pep.xml ${DATA}/sample2.pin : ${DATA}/sample2.mgf ${DATA}/db.fasta ${DATA}/comet.params ${PIPELINE_DIR}/packages.yaml
	( cd ${DATA} ; ${PIPELINE_DIRx}/howto -f ${PIPELINE_DIRx}/packages.yaml comet.exe sample2.mgf )
${DATA}/sample3.pep.xml ${DATA}/sample3.pin : ${DATA}/sample3.mgf ${DATA}/db.fasta ${DATA}/comet.params ${PIPELINE_DIR}/packages.yaml
	( cd ${DATA} ; ${PIPELINE_DIRx}/howto -f ${PIPELINE_DIRx}/packages.yaml comet.exe sample3.mgf )

# ------------------------------------------------------------------------

all:: ${DATA}/sample1.target_peptide_results.tsv ${DATA}/sample2.target_peptide_results.tsv ${DATA}/sample3.target_peptide_results.tsv

${DATA}/sample1.target_peptide_results.tsv : ${DATA}/sample1.pin ${DATA}/db.fasta ${PIPELINE_DIR}/packages.yaml
	${PIPELINE_DIR}/howto \
		-f ${PIPELINE_DIR}/packages.yaml \
		percolator ${DATA}/sample1.pin \
		--picked-protein ${DATA}/db.fasta \
		--protein-decoy-pattern DECOY_ \
		--protein-report-fragments \
		--protein-report-duplicates \
		--decoy-results-psms ${DATA}/sample1.decoy_psm_results.tsv \
		--decoy-results-peptides ${DATA}/sample1.decoy_peptide_results.tsv\
		--decoy-results-proteins ${DATA}/sample1.decoy_protein_results.tsv \
		--results-psms ${DATA}/sample1.target_psm_results.tsv \
		--results-peptides ${DATA}/sample1.target_peptide_results.tsv \
		--results-proteins ${DATA}/sample1.target_protein_results.tsv

${DATA}/sample2.target_peptide_results.tsv : ${DATA}/sample2.pin ${DATA}/db.fasta ${PIPELINE_DIR}/packages.yaml
	${PIPELINE_DIR}/howto \
		-f ${PIPELINE_DIR}/packages.yaml \
		percolator ${DATA}/sample2.pin \
		--picked-protein ${DATA}/db.fasta \
		--protein-decoy-pattern DECOY_ \
		--protein-report-fragments \
		--protein-report-duplicates \
		--decoy-results-psms ${DATA}/sample2.decoy_psm_results.tsv \
		--decoy-results-peptides ${DATA}/sample2.decoy_peptide_results.tsv\
		--decoy-results-proteins ${DATA}/sample2.decoy_protein_results.tsv \
		--results-psms ${DATA}/sample2.target_psm_results.tsv \
		--results-peptides ${DATA}/sample2.target_peptide_results.tsv \
		--results-proteins ${DATA}/sample2.target_protein_results.tsv

${DATA}/sample3.target_peptide_results.tsv : ${DATA}/sample3.pin ${DATA}/db.fasta ${PIPELINE_DIR}/packages.yaml
	${PIPELINE_DIR}/howto \
		-f ${PIPELINE_DIR}/packages.yaml \
		percolator ${DATA}/sample3.pin \
		--picked-protein ${DATA}/db.fasta \
		--protein-decoy-pattern DECOY_ \
		--protein-report-fragments \
		--protein-report-duplicates \
		--decoy-results-psms ${DATA}/sample3.decoy_psm_results.tsv \
		--decoy-results-peptides ${DATA}/sample3.decoy_peptide_results.tsv\
		--decoy-results-proteins ${DATA}/sample3.decoy_protein_results.tsv \
		--results-psms ${DATA}/sample3.target_psm_results.tsv \
		--results-peptides ${DATA}/sample3.target_peptide_results.tsv \
		--results-proteins ${DATA}/sample3.target_protein_results.tsv

# ------------------------------------------------------------------------

all:: ${DATA}/pg-search-results.gff
${DATA}/pg-search-results.gff : ${DATA}/db.fasta ${DATA}/db.gff \
		${DATA}/sample1.target_peptide_results.tsv \
		${DATA}/sample2.target_peptide_results.tsv \
		${DATA}/sample3.target_peptide_results.tsv \
		${PIPELINE_DIR}/percs2gff
	${PIPELINE_DIR}/percs2gff ${PERCS2GFF_ARGS} \
	    -r ${DATA}/perc_report.txt \
	    -o ${DATA}/pg-search-results.gff \
	    ${DATA}/db.fasta ${DATA}/db.gff \
	    ${DATA}/sample1.target_peptide_results.tsv \
	    ${DATA}/sample2.target_peptide_results.tsv \
	    ${DATA}/sample3.target_peptide_results.tsv


# ------------------------------------------------------------------------


