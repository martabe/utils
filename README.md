# utils

Collection of scripts for bioinformatics-related tasks such as formatting files.


## gemma2igv

[gemma2igv.sh](./gemma2igv.sh)

A bash script to convert GEMMA's output of linear models (`-lm` and `-lmm`) and BSLMM models into a file that can be read by IGV. The script uses the fields "chr" and "ps" unless they have value "-9". In that case the chromosome and position are extracted from the "rs" field, split by a "-".
The output is sorted by coordinate. Output has extension .gwas for the linear models, .igv for the BSLMM model. For BSLMM, one can chose to plot gamma or beta (`-v` option). The value of the parameter is shown as points by IGV.

Usage:

`./gemma2igv.sh -i lmm.assoc.txt -m lmm -v p_score -o lmm.assoc_pscore`

`./gemma2igv.sh -i bslmm.param.txt -m bslmm -v gamma -o bslmm.param_gamma`

`./gemma2igv.sh -h`


