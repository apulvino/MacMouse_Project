#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=build
#SBATCH --output=build.out
#SBATCH --error=build.err
#SBATCH --time=400:00:00
#SBATCH --mem=1T
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

source activate kneaddata
#source activate krakenuniq
#download=./krakenuniq/krakenuniq-1.0.4/krakenuniq-download
#buildk=./krakenuniq/krakenuniq-1.0.4/krakenuniq-build

READ_LEN=150

#$download
#krakenuniq-download --db ./DBDIR microbial-nt  --taxa "archaea,bacteria,viral,fungi,protozoa,parasitic_worms" --exclude-environmental-taxa --dust --threads 40

#$buildk
# this takes just over 9 days, heads up
#krakenuniq-build --db ./DBDIR --kmer-len 31 --threads 40 --taxids-for-genomes --taxids-for-sequences --jellyfish-bin ~/.conda/envs/kneaddata/bin/jellyfish

/home/atp1458/Bracken-2.9/bracken-build -d ./DBDIR -x /home/atp1458/.conda/envs/kneaddata/bin/ -t 40 -k 31 -l 150 -y krakenuniq
#/home/atp1458/Bracken-2.9/bracken-build -k 31 -t 40 -l 150 -d ./DBDIR -x /home/atp1458/.conda/envs/krakenuniq/bin/ -y krakenuniq
