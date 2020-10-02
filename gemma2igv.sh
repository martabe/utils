#!/bin/bash

# GEMMA output to IGV format
# Marta Binaghi marta.binaghi[at]ips.unibe.ch
# Created August 25th 2020
# Last modified October 2nd 2020

# Likely not the fastest script ever. Takes about 1 min
#  for a 10 million lines file.
# Note also that because IGV coordinates are 0 based, 
# in the bslmm mode I make the interval as
# POS-1,POS

usage()
{
    echo "usage: $0 -m <lm|lmm|bslmm> -i input -v <beta|gamma|p_wald|p_lrt|p_score> -o output | [-h]"
    exit 1
}

while getopts "m:i:v:o:h" opt; do
    case ${opt} in
        m )
            m=${OPTARG}
            if [ ${m} != "lm" ] && [ ${m} != "lmm" ] && [ ${p} != "bslmm" ] ; then 
                echo "-m option must be a valid value < lm | lmm | bslmm >"
                exit 1
            fi
            ;;
        i )
            i=${OPTARG}
            ;;
        v )
            v=${OPTARG}
            if [ ${m} == "lm" ] || [ ${m} == "lmm" ] && [ ${v} != "p_wald" ] && [ ${v} != "p_lrt" ] && [ ${v} != "p_score" ] ; then 
                echo "Using ${m} mode. -v option must be a valid value < p_wald | p_lrt | p_score >."
                exit 1
            elif [ ${m} == "bslmm" ] && [ ${v} != "beta" ] && [ ${v} != "gamma" ] ; then
                echo "Using ${m} mode. -v option must be a valid value < beta | gamma >."
                exit 1
            fi
            ;;
        o )
            o=${OPTARG}
            ;;
        h )
            usage
            ;;
        \? )
            echo "Something is wrong in your command"
            usage
            ;;
        : )
            echo "Invalid option: ${OPTARG} requires an argument"
            usage
            ;;
        * )
            echo "Programming error"
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# test if no options were passed
if [ $OPTIND -eq 1 ]; then 
    echo "No options were passed."
    usage
fi

# test if input file can be read
if [ ! -r ${i} ]; then
    echo "Input file ${i} cannot be read."
    exit 1
fi

# define if it's a linear model input or not
if [ ${m} == "lm" ] || [ ${m} == "lmm" ] ; then
    LM=true
else
    LM=false
fi

# create output file name (add extension)
if $LM ; then
    o=${o}.gwas
else
    o=${o}.igv
fi

if [ -f ${o} ]; then
    echo "Output file name was not provided or already exists. Use a different file name or remove it."
    exit 1
else
    # add header
    if $LM ; then
        echo -e "CHR\tBP\tSNP\tP" > ${o}
    else
        # This line is used to tell IGV how to display the value
        echo -e "#track graphType=points" > ${o} 
        echo -e "CHR\tSTART\tEND\tFEATURE\t${v}" >> ${o}
    fi
fi

echo -e "\nYou are using gemma2igv converter.
This script converts the output of GEMMA (assoc files for
LM and LMM, param for BSLMM) into a format that can be read by IGV.
The output file is sorted by coordinate.
For LM and LMM the output is in .gwas format, for BSLMM the output
is .igv format."

echo -e "\nInput file is: $i
Output file is: $o"
if $LM ; then
    echo -e "P value: $v"
else
    echo -e "BSLMM value selected: $v"
fi

# Test if chr and ps columns in input are populated (!=-9)
# using "rs" field?
RS=false
# field sep of input header
IFS="	"
# get header
firstl=$(sed '2q;d' ${i})
read -ra LINE2 <<< ${firstl}
chr="${LINE2[0]}"
ps="${LINE2[2]}"
#echo $chr
#echo $ps
if [ "${chr}" == "-9" ] || [ "${ps}" == "-9" ]; then
    RS=true
    echo -e "\nchr and ps fields in input file are missing (-9).
Chromosome and position will be taken from the "rs" column, split by '-'."
else
    echo -e "\nCoordinates will be taken from the chr and ps fields."
fi

# take relevant columns from input
# if RS, take col2 and split
# if !RS, take col1 and 3
chr_idx=$(head -1 ${i} | tr '\t' '\n' | cat -n | awk '/chr/ {print FNR}' )
rs_idx=$(head -1 ${i} | tr '\t' '\n' | cat -n | awk '/rs/ {print FNR}' ) 
ps_idx=$(head -1 ${i} | tr '\t' '\n' | cat -n | awk '/ps/ {print FNR}' )
val_idx=$(head -1 ${i} | tr '\t' '\n' | cat -n | awk -v pat="${v}" '$0 ~ pat{print FNR}')

if $LM ; then
    if $RS ; then
        tail -n +2 ${i} | cut -f $rs_idx,$val_idx | sed -r 's/([[:alnum:]]+)-([[:digit:]]+)\t/\1\t\2\t\1-\2\t/' | sort -k1,1 -k2,2n >> ${o}
    else
        tail -n +2 ${i} | cut -f $chr_idx,$ps_idx,$rs_idx,$val_idx | sort  -k1,1 -k2,2n >> ${o}
    fi
else 
    if $RS ; then
        tail -n +2 ${i} | cut -f $rs_idx,$val_idx | sed -r "s/([[:alnum:]]+)-([[:digit:]]+)\t/\1\t\2\t\2\t${v}\t/" |  awk 'OFS="\t" { print $1,$2-1,$3,$4,$5 }' | sort -k1,1 -k2,2n >> ${o}
    else
        tail -n +2 ${i} | cut -f $chr_idx,$ps_idx,$val_idx | awk -v val="${v}" 'OFS="\t" { print $1,$2-1,$2,val,$3 }' | sort  -k1,1 -k2,2n >> ${o} 
    fi
fi

#echo $chr_idx $rs_idx $ps_idx $value_idx

echo -e "\nOutput file is: ${o}."
