#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=sem
#SBATCH --output=logs/sem_%A_%a.out
#SBATCH --error=logs/sem_%A_%a.err
#SBATCH --array=1-100
#SBATCH --time=13-00:00:00
#SBATCH --mem=160G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=anthony.pulvino@northwestern.edu
#SBATCH --mail-type=END

module purge all

source activate MixOmicsDeps

#Rscript integrate.R $SLURM_ARRAY_TASK_ID

Rscript template.R $SLURM_ARRAY_TASK_ID
