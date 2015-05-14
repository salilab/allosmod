#!/bin/bash

AFIL=$1 #align.ali
LIST=$2 #list
TARG=$3 #pm.pdb

#get target sequence
i1=`grep ">" ${AFIL} | awk '{print NR,$0}' | grep -i ${TARG} | awk '(NR==1){print $1}'`
S1=(`grep -n ">" ${AFIL} |awk -F: '(NR=='${i1}'){printf $1+2" "}(NR=='${i1}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
R_TSEQ=(`awk 'BEGIN{FS=""}(NR>='${S1[0]}'&&NR<='${S1[1]}'){for(a=1;a<=NF;a++){print $a}}' ${AFIL} | sed "s/*//g"`)
NUMRES=`cat ${AFIL} | sed "s/-//g" | sed "s/\///g" | sed "s/*//g" |\
         awk 'BEGIN{FS="";a=0}(NR>='${S1[0]}'&&NR<='${S1[1]}'){a+=NF}END{print a}'`

#get pdb index in alignment file
ctr=-1
for pdb in `cat ${LIST}`; do
    ctr=$((${ctr} + 1))
    R_FIL[${ctr}]=`grep ">" ${AFIL} | awk '{print NR,$0}' | grep -i $pdb | awk '(NR==1){print $1}'`
done

#get number of templates aligned to ${TARG} residues
numTEMP=0
for i1 in ${R_FIL[@]}; do
    S1=(`grep -n ">" ${AFIL} |awk -F: '(NR=='${i1}'){printf $1+2" "}(NR=='${i1}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
    R_SEQ=(`awk 'BEGIN{FS=""}(NR>='${S1[0]}'&&NR<='${S1[1]}'){for(a=1;a<=NF;a++){print $a}}' ${AFIL} | sed "s/*//g"`)

    ctr=-1
    for tres in ${R_TSEQ[@]}; do
	ctr=$((${ctr} + 1))
	res=${R_SEQ[${ctr}]}

	if test $tres != "-" -a $tres != "/" -a $tres != "*"; then
	    if test $res != "-" -a $res != "/" -a $res != "*"; then
		numTEMP=$((${numTEMP} + 1))
	    fi
	fi
    done
done

#print NTOTAL, must be >=1 and integer, roughly equal to the number of templates per residue
echo "${numTEMP}/${NUMRES}" | bc -l | awk 'BEGIN{a=1}($1>a){a=$1}END{printf "%3.0f\n",a}' | awk '{print $1}'

