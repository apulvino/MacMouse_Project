#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=cutrefo
#SBATCH --output=cutreformat.out
#SBATCH --error=cutreformat.err
#SBATCH --time=15:00:00
#SBATCH --mem=10G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=anthony.pulvino@northwestern.edu
#SBATCH --mail-type=END

ml purge all
ml cutadapt
ml pigz

cat filenames.txt | while read line; do \
	file=$line;

	## trimming adapters and renaming

	/usr/bin/time -v cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -a "G{50}" -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -A "G{50}" \
	-o ./cutrefo${file}_R1.fastq.gz -p ./cutrefo${file}_R2.fastq.gz \
	../files/${file}_R1_001.fastq.gz ../files/${file}_R2_001.fastq.gz \
	-m 50 -q 25 -j 40

	## actual reformatting R1

        pigz -d -p 40 cutrefo${file}_R1.fastq.gz
	cp cutrefo${file}_R1.fastq cutrefo${file}_R1.fastq.tmp &&
	awk '{gsub(/ 1.*/, "")} /^@/{$0=$0""("\/1")}1' cutrefo${file}_R1.fastq.tmp | tee cutrefo${file}_R1.fastq
	pigz -p 40 cutrefo${file}_R1.fastq
	rm cutrefo${file}_R1.fastq.tmp

        ## actual reformatting R2

        pigz -d -p 40 cutrefo${file}_R2.fastq.gz
        cp cutrefo${file}_R2.fastq cutrefo${file}_R2.fastq.tmp &&
        awk '{gsub(/ 2.*/, "")}  /^@/{$0=$0""("\/2")}1' cutrefo${file}_R2.fastq.tmp | tee cutrefo${file}_R2.fastq
	pigz -p 40 cutrefo${file}_R2.fastq
	rm cutrefo${file}_R2.fastq.tmp
done

