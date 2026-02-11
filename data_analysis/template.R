#!/usr/bin/env Rscript

# ===========================
# 0. Libraries
# ===========================
library(lavaan)
library(dplyr)
library(iterators)
library(itertools)

# ===========================
# 1. Load & Prepare Data
# ===========================
microbe_df <- readRDS("X1.rds")
cecum_df   <- readRDS("X2.rds")
serum_df   <- readRDS("X3.rds")
liver_df   <- readRDS("X4.rds")

filter_mac_ud <- function(df, group_vec){
  df <- as.data.frame(df)
  keep <- sapply(df, function(f){
    mean_mac <- mean(f[group_vec=="mac"])
    mean_hum <- mean(f[group_vec=="hum"])
    mean_sqm <- mean(f[group_vec=="sqm"])
    (mean_mac>mean_hum & mean_mac>mean_sqm) | (mean_mac<mean_hum & mean_mac<mean_sqm)
  })
  df[, keep, drop=FALSE]
}

group_vec <- tolower(substr(rownames(microbe_df),1,3))
microbe_df <- filter_mac_ud(microbe_df, group_vec)
cecum_df   <- filter_mac_ud(cecum_df, group_vec)
serum_df   <- filter_mac_ud(serum_df, group_vec)
liver_df   <- filter_mac_ud(liver_df, group_vec)

prep_block <- function(df, prefix){
  df <- as.data.frame(df)
  colnames(df) <- paste0(prefix, "_", colnames(df))
  colnames(df) <- make.unique(gsub("[^0-9A-Za-z_]", "_", colnames(df)))
  as.data.frame(scale(df))
}

microbe_df <- prep_block(microbe_df, "microbe")
cecum_df   <- prep_block(cecum_df, "cecum")
serum_df   <- prep_block(serum_df, "serum")

# ===========================
# 2. Block Filters
# ===========================
block_filters <- list(
  microbe = c("microbe_Bacteroides_thetaiotaomicron","scindens","symbiosum","sulf"),
  cecum   = c("carb","mannitol","buty","buta","propa","propi","sterol","chol","sacch","ose"),
  serum   = c("carb","mannitol","buty","buta","propa","propi","sulf","cyst","sterol","chol","sacch","ose"),
  liverA  = c("Slc6a13","Csad","Cdo1","Fmo1","Gclc","Cth","Mfsd", "Slc6a6"),
  liverB  = c("Cyp","Hnf4a","Slc10a1"),
  liverC  = c("Rxr","Nr1h3","Nr1h4","Nr1i3","Nr1i2","Retsat","Rbp1"),
  liverD  = c("Cebp","Fasn","Acaca","Acacb","Sreb","Klf","Sreb","Fabp","Scd1","Acly","Slc27a5","Cidec","Adipoq", "Ppar", "Stat5", "Gpd1")
)

filter_block <- function(df, patterns, prefix){
  cols <- grepl(paste(patterns, collapse="|"), colnames(df), ignore.case=TRUE)
  if(!any(cols)) stop(paste0("❌ No features found for ", prefix))
  prep_block(df[, cols, drop=FALSE], prefix)
}

liverA <- filter_block(liver_df, block_filters$liverA, "liverA")
liverB <- filter_block(liver_df, block_filters$liverB, "liverB")
liverC <- filter_block(liver_df, block_filters$liverC, "liverC")
liverD <- filter_block(liver_df, block_filters$liverD, "liverD")

combined_df <- cbind(microbe_df, cecum_df, serum_df,
                     liverA, liverB, liverC, liverD)

block_to_features <- list(
  microbe = colnames(microbe_df),
  cecum   = colnames(cecum_df),
  serum   = colnames(serum_df),
  liverA  = colnames(liverA),
  liverB  = colnames(liverB),
  liverC  = colnames(liverC),
  liverD  = colnames(liverD)
)

get_features <- function(block){
  feats <- block_to_features[[block]]
  patterns <- block_filters[[block]]
  if(!is.null(patterns)){
    keep <- sapply(feats, function(f) any(sapply(patterns, function(p) grepl(p,f,ignore.case=TRUE))))
    feats <- feats[keep]
  }
  feats
}

# ===========================
# 3. Path templates
# ===========================
all_paths <- list(
  c("microbe","cecum","serum","liverA","liverB", "liverD"),
  c("microbe","cecum","serum","liverA","liverB","liverC","liverD"),
  c("microbe","cecum","serum","liverA","liverC","liverB","liverD"),
  c("microbe","cecum","serum","liverA","liverB", "microbe")
)

build_sem_syntax <- function(path_nodes){
  paste0(paste0(path_nodes[-1], " ~ ", path_nodes[-length(path_nodes)]), collapse="\n")
}

# ===========================
# 4. SEM fitting + streaming
# ===========================
fit_and_extract <- function(feature_path, data, bootstrap_n=50, outfile=NULL){
  # Validate directional path
  block_order <- sapply(strsplit(feature_path, "_"), `[`, 1)
  if(!any(sapply(all_paths, function(vp) identical(block_order, vp[seq_along(block_order)])))){
    message("⚠️ Skipping invalid path: ", paste(feature_path, collapse=" > "))
    return(NULL)
  }

  sem_syntax <- build_sem_syntax(feature_path)

  fit <- tryCatch(
    sem(sem_syntax, data=data, se="bootstrap", bootstrap=bootstrap_n),
    error=function(e){
      message("⚠️ SEM failed for path (truncated): ", substr(paste(feature_path, collapse=" > "),1,120))
      return(NULL)
    }
  )

  if(is.null(fit)) return(NULL)

  out <- tryCatch(
    parameterEstimates(fit, standardized=TRUE) %>%
      dplyr::filter(op=="~") %>%
      dplyr::select(lhs,rhs,est,ci.lower,ci.upper,pvalue) %>%
      dplyr::mutate(
        path_id = paste(feature_path, collapse=">"),
        mechanism = dplyr::case_when(
          grepl("carb", lhs) ~ "Both",
          grepl("Cyp2c70|Cyp2a12|Fasn|Acac|Srebp1c", lhs) ~ "Hypertrophy",
          grepl("Csad|Cdo1|Slc6a6|Wnt|Ppar", lhs) ~ "Hyperplasia",
          TRUE ~ "Incoherent"
        )
      ),
    error=function(e) NULL
  )

  if(is.null(out) || nrow(out)==0) return(NULL)

  if(!is.null(outfile)){
    write.table(out, file=outfile, sep=",", row.names=FALSE,
                col.names=!file.exists(outfile), append=TRUE, quote=FALSE)
  }

  out
}

# ===========================
# 5. Iterate over all path templates (with progress, split by job)
# ===========================
array_id <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID", unset=1))
n_jobs   <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_COUNT", unset=1))
output_file <- paste0("mini_path_table_chunk_", array_id, ".csv")

progress_interval <- 50  # how often to log

for(path_blocks in all_paths){
  # Get filtered features per block
  features_list <- lapply(path_blocks, get_features)
  
  # Skip if any block is empty
  if(any(sapply(features_list, length) == 0)){
    cat("⚠️ Skipping template due to empty block(s):",
        paste(path_blocks[sapply(features_list,length)==0], collapse=", "), "\n")
    next
  }
  
  # Print block sizes
  cat("\n🚀 Processing template:", paste(path_blocks, collapse=" > "), "\n")
  for(i in seq_along(path_blocks)){
    cat("   ", path_blocks[i], ":", length(features_list[[i]]), "features\n")
  }
  
  # All combinations
  combos <- expand.grid(features_list, stringsAsFactors=FALSE)
  total_combos <- nrow(combos)
  cat("   Total feature combinations for this template:", total_combos, "\n")
  
  # Split work across SLURM array jobs
  rows_per_job <- ceiling(total_combos / n_jobs)
  start_row <- (array_id - 1) * rows_per_job + 1
  end_row   <- min(array_id * rows_per_job, total_combos)
  job_combos <- combos[start_row:end_row, , drop=FALSE]
  
  rows_written <- 0
  
  for(i in 1:nrow(job_combos)){
    feature_path <- as.character(job_combos[i, ])
    out <- fit_and_extract(feature_path, combined_df, outfile=output_file)
    
    if(!is.null(out)) rows_written <- rows_written + nrow(out)
    
    if(i %% progress_interval == 0 || i == nrow(job_combos)){
      cat("      Progress:", i, "/", nrow(job_combos),
          "paths tested, rows written so far:", rows_written, "\n")
    }
  }
  
  cat("✅ Finished template:", paste(path_blocks, collapse=" > "), 
      "- total rows written for this job:", rows_written, "\n")
}

