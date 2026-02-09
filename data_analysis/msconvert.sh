#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=msconv
#SBATCH --output=conv.out
#SBATCH --error=conv.err
#SBATCH --time=64:00:00
#SBATCH --mem=136G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

#module load singularity/3.8.1
module load singularity

mkdir output_mzML/

mkdir output_mzML/positive_scans/
mkdir output_mzML/negative_scans/

sandbox=/projects/b1057/apulvino/pwiz_sandbox

cat /projects/b1057/apulvino/Chapter1/serum_metabolomics/raw_files/filenames.txt | while read line; do \
	file=$line;

        singularity exec --bind $PWD:$HOME \
        --writable ${sandbox} \
	mywine msconvert raw_files/${file} --mzML \
	--filter "peakPicking vendor msLevel=1-" \
	--filter "threshold absolute 2000 most-intense" \
        --filter "polarity positive" \
        --64 --zlib \
        --outdir $PWD/output_mzML/positive_scans

        singularity exec --bind $PWD:$HOME \
        --writable ${sandbox} \
        mywine msconvert raw_files/${file} --mzML \
        --filter "peakPicking vendor msLevel=1-" \
        --filter "polarity negative" \
        --64 --zlib \
        --outdir $PWD/output_mzML/negative_scans

done

##        --filter "peakPicking vendor msLevel=1-" \
##        --filter "zeroSamples removeExtra 1-" \
