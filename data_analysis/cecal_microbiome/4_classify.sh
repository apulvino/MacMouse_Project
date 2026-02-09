#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=k2b
#SBATCH --output=k2b.out
#SBATCH --error=k2b.err
#SBATCH --time=900:00:00
#SBATCH --mem=180G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=48
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

#modified script to run kraken2 bracken pipeline for single-end reads adapted from
#https://www.nicholas-ollberding.com/post/profiling-of-shotgun-metagenomic-sequence-data-using-kraken2-bracken-and-humann2/

#notes: - program assumes fastq files residing in single folder (typically will be kneaddata_out folder)
#       - modify if have fasta or other file name (e.g., .fna, .fq, etc.)
#       - program assumes reads have already been quality filtered and trimmed to a min of 90bp
#       - if have shorter min read length then need to build and use bracken db built for shorter read length

#       - program generates k2 read mappings and bracken abundance estimation at the phylum, genus, and species levels
#       - modify if want output for other levels
#       - k2 confidence set to 0.1 and bracken threshold to t-10; consider modifying to reduce FPR as needed

#       - requesting 32 cores, 120G RAM, and 8 hr wall time; see: https://bmi.cchmc.org/resources/software/lsf-examples

#Navigate to folder containing fastq files: (CHANGE ME)
#cd /projects/b1057/apulvino/1_cecal_shotgun/kneaddata/kneaddata_output/


#Load modules
source activate kneaddata
## for bracken commands you'll need to point to binary install as necessary...

#Classify reads with kraken2
mkdir /projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2/k2_class_outputs
mkdir /projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2/k2_unclass_outputs
mkdir /projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2/k2_reports

db=/projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2/DBDIR
to_fastqs=/projects/b1057/apulvino/1_cecal_shotgun/kneaddata/kneaddata_output
reports_dir=/projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2/k2_reports


#/projects/b1057/apulvino/1_cecal_shotgun/kneaddata/kneaddata_output/cutrefo17-2-SbMm-USA-23-ATP-1873_S386_L005_R1_kneaddata_paired_1.fastq
cat /projects/b1057/apulvino/1_cecal_shotgun/fastqs/trimmed_files/filenames.txt | while read line; do \
	file=$line;

	#kraken2 --db $db \
	#--confidence 0.1 \
	#--threads 40 \
	#--use-names \
	#--output k2_outputs/${file}_output.txt \
	#--report k2_reports/${file}_report.txt \
	#--paired $to_fastqs/cutrefo${file}_R1_kneaddata_paired_1.fastq $to_fastqs/cutrefo${file}_R1_kneaddata_paired_2.fastq

	krakenuniq --db $db \
	--exact \
	--threads 48 \
	--check-names \
	--classified-out k2_class_outputs/${file}_output.txt \
	--unclassified-out k2_unclass_outputs/${file}_output.txt \
	--report-file k2_reports/${file}_report.txt \
	--paired $to_fastqs/cutrefo${file}_R1_kneaddata_paired_1.fastq $to_fastqs/cutrefo${file}_R1_kneaddata_paired_2.fastq

done
