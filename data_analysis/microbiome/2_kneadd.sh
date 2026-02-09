#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=kneaddata
#SBATCH --output=kneaddata.out
#SBATCH --error=kneaddata.err
#SBATCH --time=72:00:00
#SBATCH --mem=80G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

source activate kneaddata

## make a dir: ./MmGRCm39db and add Mus_musculus.GRCm39.dna.primary_assembly.fa to it from ensembl
#mkdir kneaddata_output

#kneaddata_build_database ./MmGRCm39db/Mus_musculus.GRCm39.dna.primary_assembly.fa
#bowtie2-build ./MmGRCm39db/Mus_musculus.GRCm39.dna.primary_assembly.fa \
#./MmGRCm39db/MmGRCm39dbFiles

cat /projects/b1057/apulvino/1_cecal_shotgun/fastqs/trimmed_files/filenames.txt | while read line; do \
        file=$line;

	kneaddata \
	--input1 ../fastqs/trimmed_files/cutrefo${file}_R1.fastq.gz \
	--input2 ../fastqs/trimmed_files/cutrefo${file}_R2.fastq.gz \
	--output ./kneaddata_output --bypass-trim \
	--reference-db ./MmGRCm39db --threads 40 \
	--bowtie2 ~/.conda/envs/kneaddata/bin/ --bowtie2-options="-p 40 --reorder"
	
done

kneaddata_read_count_table --input ./kneaddata_output --output ./kneaddata_output/kneaddata_read_counts.txt


