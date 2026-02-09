#!/bin/bash

#SBATCH --account=a9009
#SBATCH --partition=a9009
#SBATCH --job-name=ctdbalnct
#SBATCH --output=ctdbalnct.out
#SBATCH --error=ctdbalnct.err
#SBATCH --time=8:00:00
#SBATCH --mem=136G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

module purge all
module load cutadapt/4.2
module load STAR/2.7.9a


#gunzip GRCm39_db/Mus_musculus.GRCm39.dna.primary_assembly.fa.gz
#gunzip GRCm39_db/Mus_musculus.GRCm39.110.gtf.gz

db=/projects/b1057/apulvino/pilot_liverRNAseq/GRCm39_db
aln_output=/projects/b1057/apulvino/pilot_liverRNAseq/aln_output
ct_output=/projects/b1057/apulvino/pilot_liverRNAseq/ct_output
untrimmed_fastqs=/projects/b1057/apulvino/pilot_liverRNAseq/fastqs/adult/
trimmed_fastqs=/projects/b1057/apulvino/pilot_liverRNAseq/fastqs/adult/trimmed_fastqs

#### cut
cat /projects/b1057/apulvino/pilot_liverRNAseq/fastqs/adult/filenames.txt | while read line; do \
	file=$line;

#	/usr/bin/time -v cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -a "A{20}" -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -A "A{20}" \
#	-o fastqs/adult/trimmed_fastqs/${file}L001_R1_001_cut.fastq.gz -p fastqs/adult/trimmed_fastqs/${file}L002_R1_001_cut.fastq.gz \
#	fastqs/adult/${file}L001_R1_001.fastq.gz fastqs/adult/${file}L002_R_001.fastq.gz \
#	-m 50 -j 40

       /usr/bin/time -v cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -a "A{31}" -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -A "A{31}" \
       -o fastqs/adult/trimmed2/${file}L001_R1_001_cut.fastq.gz -p fastqs/adult/trimmed2/${file}L002_R1_001_cut.fastq.gz \
       fastqs/adult/${file}L001_R1_001.fastq.gz fastqs/adult/${file}L002_R1_001.fastq.gz \
       -m 50 -j 40

done

#### mkdb
#/usr/bin/time -v STAR --runThreadN 40 \
#--runMode genomeGenerate \
#--genomeDir $db \
#--genomeFastaFiles $db/Mus_musculus.GRCm39.dna.primary_assembly.fa \
#--sjdbGTFfile $db/Mus_musculus.GRCm39.110.gtf

#### aln
cat /projects/b1057/apulvino/pilot_liverRNAseq/fastqs/adult/filenames.txt | while read line; do \
	file=$line;

	/usr/bin/time -v STAR --runThreadN 40 \
	--runMode alignReads \
	--outFilterMultimapNmax 1 \
	--outSAMunmapped Within KeepPairs \
	--alignIntronMax 1000000 --alignMatesGapMax 1000000 \
	--readFilesCommand zcat \
	--readFilesIn $trimmed_fastqs/${file}L001_R1_001_cut.fastq.gz $trimmed_fastqs/${file}L002_R1_001_cut.fastq.gz \
	--genomeDir GRCm39_db \
	--outFileNamePrefix $aln_output/${file} \
	--outSAMtype BAM SortedByCoordinate
done

module purge all
module load samtools/1.14
module load htseq/2.0.2

#### ct (and samtools index)
cat /projects/b1057/apulvino/pilot_liverRNAseq/fastqs/adult/filenames.txt | while read line; do \
        file=$line;

	samtools index -@ 40 $aln_output/${file}Aligned.sortedByCoord.out.bam
	
	/usr/bin/time -v htseq-count -f bam -s no -t exon -m union -r pos \
        $aln_output/${file}Aligned.sortedByCoord.out.bam $db/Mus_musculus.GRCm39.110.gtf \
        > $ct_output/${file}readcounts.txt
done

#gzip Mus_musculus.GRCm39.dna.primary_assembly.fa
#gzip Mus_musculus.GRCm39.110.gtf
