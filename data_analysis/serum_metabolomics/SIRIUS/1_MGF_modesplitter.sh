#!/bin/bash

#split by ion mode, spec input mgf from tidymass, save matches to desig outfile 
search="$1"
input="$2"
output="$3"

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

##### EXAMPLE RUN:
#### ./MGF_modesplitter.sh NEG ms2_data_1.mgf neg_mode.mgf
