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
unlink("/projects/b1057/apulvino/Chapter1/cecal_metabolomics/output_mzML/positive_scans/Result/", recursive = TRUE, force = TRUE)
unlink("/projects/b1057/apulvino/Chapter1/cecal_metabolomics/output_mzML/negative_scans/Result/", recursive = TRUE, force = TRUE)
## https://tidymass.github.io/massprocesser/articles/raw_data_processing.html
### positive mode
process_data(
  path = "/projects/b1057/apulvino/Chapter1/cecal_metabolomics/output_mzML/positive_scans",
  polarity = "positive",
  ppm = 15,                           # Tight precursor match to reduce ID noise
  peakwidth = c(5, 220),              # Long upper bound to recover bile conjugate tails
  snthresh = 5,                       # Slightly relaxed to capture mid-intensity bile features
  noise = 300,                        # Tolerate more low-abundance, real signals
  prefilter = c(2, 90),              # Weaker low-level noise gate
  min_fraction = 0.69,                 # Keeps mac-specific and consistent microbially driven peaks
  fill_peaks = TRUE,
  bw = 30,                            # Increase to stabilize RT alignment in the 700–900s window
  output_tic = TRUE,
  output_rt_correction_plot = TRUE,
  threads = 16
)

load("/projects/b1057/apulvino/Chapter1/cecal_metabolomics/output_mzML/positive_scans/Result/object")
write_rds(object,"object_pos.Rds")

### negative mode
process_data(
  path = "/projects/b1057/apulvino/Chapter1/cecal_metabolomics/output_mzML/negative_scans",
  polarity = "negative",
  ppm = 20,                       # Still tight for confident [M–H]⁻ matching
  peakwidth = c(6, 220),          # Allows longer-tailed bile metabolites (esp. conjugates)
  snthresh = 5,                   # Slightly raised to suppress baseline drift, but keeps low-intensity sulfates
  noise = 250,                    # Balanced — not too strict, not too permissive
  prefilter = c(2, 30),          # Allows real but mid-intensity late features
  min_fraction = 0.3,             # Keeps bile/SCFA intermediates that are group-specific
  fill_peaks = TRUE,
  bw = 30,                        # Accommodates RT drift (up to ±10–15 s seen in earlier plots)
  output_tic = TRUE,
  output_rt_correction_plot = TRUE,
  threads = 16
)

load("/projects/b1057/apulvino/Chapter1/cecal_metabolomics/output_mzML/negative_scans/Result/object")
write_rds(object,"object_neg.Rds")
