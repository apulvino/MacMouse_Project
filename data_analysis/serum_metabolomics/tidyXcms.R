#!/usr/bin/env Rscript

### making conda env for these 3, see submission script
#library(xcms)
#library(MSnbase)
#library(mzR)
#library(devtools)
#library(tidyverse)
#library(remotes)
#library(devtools)
#library(readr)

############ these are the packages that will need to be installed with devtools::install_github in your session beforehand
############ the ones above and others in the .yml in this directory will be sufficient to get massprocesser up and running

#devtools::install_github("tidymass/masstools", force = TRUE, upgrade = "never", quiet = FALSE, dependencies = FALSE)
#devtools::install_github("tidymass/massdataset", force = TRUE, upgrade = "never", quiet = FALSE, dependencies = FALSE)
#devtools::install_github("apulvino/massprocesser", force = TRUE, upgrade = "never", quiet = FALSE, dependencies = FALSE)
# selecting 3 to make sure nothing gets weird if i do choose to update... first time doing this
# restarting session then trying the following:
#devtools::install_github("tidymass/massdataset", upgrade = "never", dependencies = FALSE, build_vignettes = FALSE, force = FALSE)
#library(massdataset)
#remotes::install_github("apulvino/massprocesser", upgrade = "never", dependencies = FALSE, build_vignettes = FALSE, force = TRUE)
library(massprocesser)
library(readr)

#### commands re-use old data if prev. output (if you already ran this once) isn't deleted so start w/ removal
#### WARNING DO NOT REMOVE ENTIRE POSITIVE/NEGATIVE SCANS DIRECTORY, YOUR MZMLs ARE IN THERE
unlink("/projects/b1057/apulvino/Chapter1/serum_metabolomics/output_mzML/positive_scans/Result/", recursive = TRUE, force = TRUE)
unlink("/projects/b1057/apulvino/Chapter1/serum_metabolomics/output_mzML/negative_scans/Result/", recursive = TRUE, force = TRUE)
## https://tidymass.github.io/massprocesser/articles/raw_data_processing.html
## POSITIVE MODE
# POSITIVE MODE — Ultra-Inclusive
process_data(
  path = "/projects/b1057/apulvino/Chapter1/serum_metabolomics/output_mzML/positive_scans",
  polarity = "positive",
  ppm = 20,                      # Tighten slightly for early noise control
  peakwidth = c(8, 140),         # Avoid early spiky peaks + control late RT smear
  snthresh = 5,                  # Cut noisy spikes without losing moderate signals
  noise = 500,                    # Trim very low-level artifacts in early TIC
  prefilter = c(3, 80),          # Keep mid-strength true metabolites only
  min_fraction = 0.04,           # Still allows subgroup-specific compounds
  fill_peaks = TRUE,
  bw = 20,                       # Sharper RT correction for post-500s drift
  output_tic = TRUE,
  output_rt_correction_plot = TRUE,
  threads = 40
)

load("/projects/b1057/apulvino/Chapter1/serum_metabolomics/output_mzML/positive_scans/Result/object")
write_rds(object, "object_pos.Rds")

# NEGATIVE MODE — Ultra-Inclusive
process_data(
  path = "/projects/b1057/apulvino/Chapter1/serum_metabolomics/output_mzML/negative_scans",
  polarity = "negative",
  ppm = 30,                      # Widened slightly to merge fragmented bile acids
  peakwidth = c(3, 150),         # Covers SCFAs to bile conjugates, keeps peak shapes tight
  snthresh = 6,                  # Very permissive to weak, real features
  noise = 500,                   # Includes low-abundance signals
  prefilter = c(2, 15),          # Allows weak/rare but structured peaks
  min_fraction = 0.4,           # Keeps subgroup- or mac-specific compounds
  fill_peaks = TRUE,
  bw = 20,                       # Helps control RT smear post-500s without overgrouping
  output_tic = TRUE,
  output_rt_correction_plot = TRUE,
  threads = 40
)

load("/projects/b1057/apulvino/Chapter1/serum_metabolomics/output_mzML/negative_scans/Result/object")
write_rds(object, "object_neg.Rds")
