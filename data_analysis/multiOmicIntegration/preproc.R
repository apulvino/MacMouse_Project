#!/usr/bin/env Rscript

library(dplyr)
library(tidyr)
library(data.table)
library(biomaRt)
library(tibble)

set.seed(123)
### See 3nMicrobeCecumSerum.Rmd for blocks of code used to generate these objects
# diff abundant metabolites and microbes
#HsMmSb_MouseRNAseq.Rmd blocks 1-2 is where this file was first created
result.metabomat_microbe <- data.frame(data.table::fread("clippedMicro.csv", sep = ","))
rownames(result.metabomat_microbe) <- result.metabomat_microbe$V1
result.metabomat_microbe$V1 <- NULL
result.metabomat_microbe$samples <- NULL
result.metabomat_microbe <- t(result.metabomat_microbe)

result.metabomat_liver <- data.frame(data.table::fread("clippedGene.csv", sep = ","))
rownames(result.metabomat_liver) <- result.metabomat_liver$V1
result.metabomat_liver$V1 <- NULL
result.metabomat_liver$samples <- NULL
colnames(result.metabomat_liver) <- c("sqm10","sqm12","hum22","mac4","mac3","hum24","sqm16","mac1",
  "sqm13","hum19","sqm17","mac5","sqm15","hum23","hum20",
  "hum21","mac6","mac8","hum25","sqm18","sqm9","mac2",
  "mac7","hum26","sqm14","sqm11")
#MetabolomicsFinalReport.Rmd block 1 is where this file was first created
## commenting out the total.score filtering after reading in metabolomic data given diablo is responsible for feature selection
## as well as interdataset corr in this analysis and slice_max which picks an annotated compound if it has the same variable_id by which has the highest total score...
## which is not a bad idea for feature selection to weed out unlikely annotations but we want to let diablo handle this 
result.metabomat_cecum <- readr::read_csv("clippedCecum.csv") #%>% filter(Total.score > 0.99)
result.metabomat_cecum <- result.metabomat_cecum %>%
  group_by(variable_id) %>%
  filter(Total.score > 0.9 & mz.match.score > 0.99) %>% 
  #slice_max(Total.score, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  column_to_rownames("Compound.name")
result.metabomat_cecum <- result.metabomat_cecum[, grep("Ben.Oli", colnames(result.metabomat_cecum))]
colnames(result.metabomat_cecum) <- c("mac1","mac2","mac3","mac4","mac5","mac6","mac7","mac8",
                                      "sqm9", "sqm10","sqm11", "sqm12","sqm13", "sqm14","sqm15", "sqm16","sqm17", "sqm18",
                                      "hum19","hum20","hum21","hum22","hum23","hum24","hum25","hum26")
# result.metabomat_cecum <- result.metabomat_cecum[grep("cholic|cholest|cholate|cholan|phospho|bili",
#                                                             rownames(result.metabomat_cecum),
#                                                             value = TRUE), ]
#MetabolomicsFinalReport_serum.Rmd block 1 is where this file was first created 
result.metabomat_serum <- readr::read_csv("clippedSerum.csv") #%>% filter(Total.score > 0.99)
result.metabomat_serum <- result.metabomat_serum %>% 
  group_by(variable_id) %>%
  filter(Total.score > 0.9 & mz.match.score > 0.99) %>% 
  #slice_max(Total.score, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  column_to_rownames("Compound.name")
result.metabomat_serum <- result.metabomat_serum[, grep("Ben.Ant", colnames(result.metabomat_serum))]
colnames(result.metabomat_serum) <- c("mac1","mac2","mac3","mac4","mac5","mac6","mac7","mac8",
                                     "sqm10","sqm11", "sqm12","sqm13", "sqm16","sqm17", "sqm18",
                                      "hum19","hum20","hum21","hum22","hum23","hum24")
## FIX: ENSEMBL GENE ID into GENE NAMES
# Clear old cache
biomartCacheClear()

# Per-task isolated cache
tmpdir <- file.path(tempdir(), paste0("bioc_cache_", Sys.getpid()))
dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)
Sys.setenv(BIOC_CACHE_DIR = tmpdir)

mart <- useDataset("mmusculus_gene_ensembl", useMart("ensembl"))
opts <- listAttributes(mart)
bridge <- getBM(filters = "ensembl_gene_id",
               attributes = c("ensembl_gene_id","external_gene_name"),
               values = rownames(result.metabomat_liver),
               mart = mart)
result.metabomat_liver$ensembl_gene_id <- rownames(result.metabomat_liver)
result.metabomat_liver <- merge(bridge, result.metabomat_liver, by = "ensembl_gene_id")
result.metabomat_liver$ensembl_gene_id <- NULL
#remove rows that have an empty string in slot external_gene_name
result.metabomat_liver <- result.metabomat_liver[result.metabomat_liver$external_gene_name != "", ]
rownames(result.metabomat_liver) <- result.metabomat_liver$external_gene_name
result.metabomat_liver$external_gene_name <- NULL

#X1 <- t(result.metabomat_microbe)
X1 <- result.metabomat_microbe
# run the below ONLY ONCE BUT DO MAKE SURE YOU RUN IT
colnames(X1) <- sub(".*s__", "", colnames(X1))
X2 <- t(result.metabomat_cecum)
X3 <- t(result.metabomat_serum)
X4 <- t(result.metabomat_liver)

# order so rows in dataframes match one another
X1 <- X1[match(rownames(X3), rownames(X1)), ] %>% na.omit()
X2 <- X2[match(rownames(X1), rownames(X2)), ] %>% na.omit()
X3 <- X3[match(rownames(X1), rownames(X3)), ] %>% na.omit()
X4 <- X4[match(rownames(X3), rownames(X4)), ]

saveRDS(X1, "X1.rds")
saveRDS(X2, "X2.rds")
saveRDS(X3, "X3.rds")
saveRDS(X4, "X4.rds")
