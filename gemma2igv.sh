#!/bin/bash

# GEMMA linear model output to IGV format
# Marta Binaghi marta.binaghi[at]ips.unibe.ch
# Created August 25th 2020
# Last modified August 26th 2020

# Likely not the fastest script ever. Takes about 1 min
#  for a 10 million lines file.

usage()
{
    echo "usage: $0 -i input -p <p_wald|p_lrt|p_score> -o output | [-h]"
    exit 1
}

while getopts "i:p:o:h" opt; do
    case ${opt} in
        i )
            i=${OPTARG}
            ;;
        p )
            p=${OPTARG}
            if [ ${p} != "p_wald" ] && [ ${p} != "p_lrt" ] && [ ${p} != "p_score" ] ; then 
                echo "-p option must be a valid value < p_wald | p_lrt | p_score >"
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
    echo "No options were passed"
    usage
fi

# test if input file can be read
if [ ! -r ${i} ]; then
    echo "Input file ${i} cannot be read."
    exit 1
fi

# create output file
if [ -f ${o} ]; then
    echo "Output file was not provided or already exists. Use a different file name or remove it."
    exit 1
else
    # add header
    echo -e "CHR\tBP\tSNP\tP" > ${o}
fi

echo -e "\nYou are using gemma2igv converter.
This script converts the output of GEMMA linear models
(LM and LMM) into a format that can be read by IGV.
The output file is already sorted."

echo -e "\nInput file is: $i
Output file is: $o
P value: $p"

# Test if chr and ps columns in gemma assoc.txt are populated (!=-9)
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
p_idx=$(head -1 ${i} | tr '\t' '\n' | cat -n | awk -v pat="${p}" '$0 ~ pat{print FNR}' )

#echo $chr_idx $rs_idx $ps_idx $p_idx

if $RS ; then
   tail -n +2 ${i} | cut -f $rs_idx,$p_idx | sed -r 's/([[:alnum:]]+)-([[:digit:]]+)\t/\1\t\2\t\1-\2\t/' | sort -k1,1 -k2,2 >> ${o}
else
   tail -n +2 ${i} | cut -f $chr_idx,$ps_idx,$rs_idx,$p_idx | sort  -k1,1 -k2,2 >> ${o}
fi

echo -e "\nOutput file is: ${o}."
