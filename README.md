# utils

Collection of scripts for bioinformatics-related tasks such as formatting files.


## gemma2igv

A bash script to convert GEMMA's output of linear models (`-lm` and `-lmm`) into a file that can be read by IGV. The script uses the fields "chr" and "ps" unless they have value "-9". In that case the chromosome and position are extracted from the "rs" field, split by a "-".
The output is sorted by coordinate.

[gemma2igv.sh](./gemma2igv.sh)
