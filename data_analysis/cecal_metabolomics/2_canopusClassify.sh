#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=sirius
#SBATCH --output=sirius.out
#SBATCH --error=sirius.err
#SBATCH --time=56:00:00
#SBATCH --mem=280G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

source activate sirius-ms

#make login creds a secret dotfile and source it in
source .sirius_credentials
pos_mgf="pos_ms2_data_1.mgf"
neg_mgf="neg_ms2_data_1.mgf"

sirius_output="sirius_results"
mkdir "${sirius_output}"

sirius login --user-env SIRIUS_USER \
--password-env SIRIUS_PASS \
--request-token-only

### were doing this run on mgf output ms2 spectra before the annotation with databases that was done in tidymass
### in that workflow -- i come out with only neg mode scans which have ms2 spectra after annotation
### but prior to that step i have 258 in pos mode... since the purpose of running sirius is mostly canopus results--
### which provide compound formula/class level annotation info -- it's safe to run this with tidymass pre-annotation ms2
### after this -- results can be cross-referenced to tidymass annotation table or otherwise analyzed independently but complementary to
### existing results from tidymass annotation -> FELLA anno enrichment and network results

# running in db free mode for pos and neg scans separate, can cat out files after
# increasing ppm a bit to more closely reflect settings used in tidymass/xcms peak picking;
# updating elements considered to include all possible available elements for consideration
sirius --input "${pos_mgf}" --output "${sirius_output}"/PosScans.sirius --log ALL --cores 16 \
formulas --profile orbitrap --ppm-max 5 --ppm-max-ms2 10 --candidates 15 --elements-considered CHNOPSCl \
zodiac \
fingerprints \
classes \
structures --exp EXACT \
write-summaries --top-hit-summary --chemvista --feature-quality-summary --full-summary

sirius --input "${neg_mgf}" --output "${sirius_output}"/NegScans.sirius --log ALL --cores 16 \
formulas --profile orbitrap --ppm-max 5 --ppm-max-ms2 10 --candidates 15 --elements-considered CHNOPSCl \
zodiac \
fingerprints \
classes \
structures --exp EXACT \
write-summaries --top-hit-summary --chemvista --feature-quality-summary --full-summary
