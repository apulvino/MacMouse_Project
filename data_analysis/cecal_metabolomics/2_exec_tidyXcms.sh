#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=tidyXcms
#SBATCH --output=tidyXcms.out
#SBATCH --error=tidyXcms.err
#SBATCH --time=10:00
#SBATCH --mem=80G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=anthony.pulvino@northwestern.edu
#SBATCH --mail-type=END

module purge all
#module load openssl/1.1.1u
#module load curl/7.88.1-gcc-12.3.0
#module load R/4.4.0

#export PKG_CONFIG_PATH=/software/openssl/1.1.1u-scotty/env/lib/pkgconfig:$PKG_CONFIG_PATH
#export LD_LIBRARY_PATH=/software/openssl/1.1.1u-scotty/env/lib:$LD_LIBRARY_PATH
#export PATH=/software/openssl/1.1.1u-scotty/env/bin:$PATH
#export CPATH=/software/openssl/1.1.1u-scotty/env/include:$CPATH
#export LIBRARY_PATH=/software/openssl/1.1.1u-scotty/env/lib:$LIBRARY_PATH

source activate tidymassDeps

Rscript tidyXcms.R
