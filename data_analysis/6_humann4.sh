#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=humann3
#SBATCH --output=humann.out
#SBATCH --error=humann.err
#SBATCH --time=72:00:00
#SBATCH --mem=40G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

source activate humann_4.0.0.alpha.1

#Paths
to_fastqs=/projects/b1057/apulvino/1_cecal_shotgun/kneaddata/kneaddata_output

#Concatenate files
#mkdir output_cat

#for fastq in "${to_fastqs}"/*_kneaddata_paired_1.fastq; do \
#	sec_in_pair="${fastq/_paired_1/_paired_2}"
#	cat "${fastq}" "${sec_in_pair}" > output_cat/"cat"_$(basename $fastq)
#done

cd output_cat

#for file in *; do \
#	mv "${file}" "${file/_R1_kneaddata_paired_1/}"
#done

for samp in *.fastq; do \
	humann --input $samp \
	--output hmn_output \
	--metaphlan /projects/b1057/apulvino/.conda/envs/humann_4.0.0.alpha.1/bin/metaphlan \
	--metaphlan-options "-t rel_ab_w_read_stats --index mpa_vJun23_CHOCOPhlAnSGB_202403" \
	--nucleotide-database /projects/b1057/apulvino/1_cecal_shotgun/humann3/db_install/chocophlan \
	--protein-database /projects/b1057/apulvino/1_cecal_shotgun/humann3/db_install/uniref \
	--threads 40
done

#Join all gene family and pathway abudance files
humann_join_tables --input hmn_output --file_name pathabundance --output humann_pathabundance.tsv
humann_join_tables --input hmn_output --file_name genefamilies --output humann_genefamilies.tsv

#Normalizing RPKs to CPM
humann_renorm_table --input humann_pathabundance.tsv --units cpm --output humann_pathabundance_cpm.tsv
humann_renorm_table --input humann_genefamilies.tsv --units cpm --output humann_genefamilies_cpm.tsv

#Generate stratified tables
humann_split_stratified_table --input humann_pathabundance_cpm.tsv --output ./
humann_split_stratified_table --input humann_genefamilies_cpm.tsv --output ./

#Cleaning up file structure
mkdir hmn_pathway_abundance_files
mkdir hmn_genefamily_abundance_files

mv *pathabundance* hmn_pathway_abundance_files/.
mv *genefamilies* hmn_genefamily_abundance_files/.

# big thanks to ollberding https://www.nicholas-ollberding.com/post/profiling-of-shotgun-metagenomic-sequence-data-using-kraken2-bracken-and-humann2/
