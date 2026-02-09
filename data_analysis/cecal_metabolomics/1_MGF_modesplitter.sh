#!/bin/bash

search="$1"       # e.g., "pos"
input="$2"        # input MGF file
output="$3"       # output file to save matches

awk -v pattern="$search" '
  BEGIN { IGNORECASE=1; block="" }
  /^BEGIN IONS/ { block=$0 "\n"; inside=1; next }
  /^END IONS/ {
    block = block $0 "\n"
    inside=0
    if (block ~ pattern) print block
    block=""
    next
  }
  inside { block = block $0 "\n" }
' "$input" > "$output"

##EXAMPLE RUN:
#./MGF_modesplitter.sh NEG ms2_data_1.mgf neg_mode.mgf
