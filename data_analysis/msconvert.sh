#!/bin/bash

#SBATCH --account=b1042
#SBATCH --partition=genomicslong
#SBATCH --job-name=msconv
#SBATCH --output=tconv.out
#SBATCH --error=tconv.err
#SBATCH --time=1:00:00
#SBATCH --mem=2G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

module load singularity

mkdir output_mzML/

mkdir output_mzML/positive_scans/
mkdir output_mzML/negative_scans/

# path to sandbox
sandbox=/projects/b1057/apulvino/pwiz_sandbox/

cat /projects/b1057/apulvino/Chapter1/cecal_metabolomics/raw_files/filenames.txt | while read line; do \
	file=$line;

        singularity exec --bind $PWD:$HOME \
        --writable ${sandbox} \
        mywine msconvert raw_files/${file} --mzML \
        --filter "peakPicking vendor msLevel=1-" \
        --filter "zeroSamples removeExtra 1-" \
        --filter "polarity positive" \
        --64 --zlib \
        --outdir $PWD/output_mzML/positive_scans

        singularity exec --bind $PWD:$HOME \
        --writable ${sandbox} \
	mywine msconvert raw_files/${file} --mzML \
	--filter "peakPicking vendor msLevel=1-" \
	--filter "zeroSamples removeExtra 1-" \
	--filter "polarity negative" \
	--64 --zlib \
	--outdir $PWD/output_mzML/negative_scans

done

