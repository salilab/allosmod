#!/bin/bash
#check alignment before job submission, put least important errors first


DIR=$1 #path to alignment and list files

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Get the 'allosmod' binary in the path
. /etc/profile
module load allosmod

cd $DIR

#get rid of odd newline problems
R_FIL=(align.ali list `cat list`)
for fil in ${R_FIL[@]}; do
    awk '{print $0}' $fil | sed 's/\o015//g' >tempra441; mv tempra441 $fil
done

i1=`grep ">" align.ali | awk '{print NR,$0}' | grep -i pm.pdb | awk '(NR==1){print $1}'`
S1=(`grep -n ">" align.ali |awk -F: '(NR=='${i1}'){printf $1+2" "}(NR=='${i1}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
seq1=(`awk 'BEGIN{FS=""}(NR>='${S1[0]}'&&NR<='${S1[1]}'){for(a=1;a<=NF;a++){print $a}}' align.ali | sed "s/*//g"`)

#check length of alignment entries
errorlength=0
for fil in `cat list`; do
    i2=`grep ">" align.ali | awk '{print NR,$0}' | grep -i ${fil} | awk '(NR==1){print $1}'`
    S2=(`grep -n ">" align.ali |awk -F: '(NR=='${i2}'){printf $1+2" "}(NR=='${i2}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
    seq2=(`awk 'BEGIN{FS=""}(NR>='${S2[0]}'&&NR<='${S2[1]}'){for(a=1;a<=NF;a++){print $a}}' align.ali | sed "s/*//g"`)
    if test `echo "${#seq1[@]}!=${#seq2[@]}" |bc -l` -eq 1; then
	errorlength=1; break 2
    fi
done

if test `echo "$errorlength==1" |bc -l` -eq 1; then echo errorlength > align.ali; exit; fi

#check all block residues input sequence are aligned to a block residue in a template sequence
errorblock=0
ctr=-1
for i in ${seq1[@]}; do
    ctr=$((${ctr} + 1))
    if test $i == "."; then
	errorblock=1
	for fil in `cat list`; do
	    i2=`grep ">" align.ali | awk '{print NR,$0}' | grep -i ${fil} | awk '(NR==1){print $1}'`
	    S2=(`grep -n ">" align.ali |awk -F: '(NR=='${i2}'){printf $1+2" "}(NR=='${i2}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
	    seq2=(`awk 'BEGIN{FS=""}(NR>='${S2[0]}'&&NR<='${S2[1]}'){for(a=1;a<=NF;a++){print $a}}' align.ali | sed "s/*//g"`)

	    j=${seq2[${ctr}]}
	    if test $j != "-" -a $j != "/"; then
		errorblock=0
	    fi
	done
	if test $errorblock == "1"; then
	    break 3
	fi
    fi
done

if test `echo "$errorblock==1" |bc -l` -eq 1; then echo errorblock > align.ali; exit; fi

#... and vice versa, all pdb file block res must align to non amino acid
for fil in `cat list`; do
    i2=`grep ">" align.ali | awk '{print NR,$0}' | grep -i ${fil} | awk '(NR==1){print $1}'`
    S2=(`grep -n ">" align.ali |awk -F: '(NR=='${i2}'){printf $1+2" "}(NR=='${i2}'+1){printf $1-1" "}' |\
         awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
    seq2=(`awk 'BEGIN{FS=""}(NR>='${S2[0]}'&&NR<='${S2[1]}'){for(a=1;a<=NF;a++){print $a}}' align.ali | sed "s/*//g"`)

    ctr=-1
    errorblock=0
    for i in ${seq2[@]}; do
	ctr=$((${ctr} + 1))
	if test $i == "."; then

	    j=${seq1[${ctr}]}
	    if test $j != "-" -a $j != "." -a $j != "/"; then
		errorblock=1
	    fi
	fi
    done
    if test $errorblock == "1"; then
	break 3
    fi
done

if test `echo "$errorblock==1" |bc -l` -eq 1; then echo errorblock > align.ali; exit; fi

#pdb's match sequence in align
errorseq=0
for fil in `cat list`; do
    i2=`grep ">" align.ali | awk '{print NR,$0}' | grep -i ${fil} | awk '(NR==1){print $1}'`
    S2=(`grep -n ">" align.ali |awk -F: '(NR=='${i2}'){printf $1+2" "}(NR=='${i2}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
    seq2=(`awk 'BEGIN{FS=""}(NR>='${S2[0]}'&&NR<='${S2[1]}'){for(a=1;a<=NF;a++){print $a}}' align.ali | sed "s/*//g" | sed "s/-//g" | sed "s/\///g"`)

    allosmod pdb2ali $fil >temp3910
    Sf=(3 9999)
    seqf=(`awk 'BEGIN{FS=""}(NR>='${Sf[0]}'&&NR<='${Sf[1]}'){for(a=1;a<=NF;a++){print $a}}' temp3910 | sed "s/*//g" | sed "s/\///g"`)

    if test `echo "${#seq2[@]}!=${#seqf[@]}" |bc -l` -eq 1; then
	errorseq=1; break
    fi

    ctr=-1
    for i in ${seq2[@]}; do
	ctr=$((${ctr} + 1))
	j=${seqf[${ctr}]}
	if test $i != $j; then
	    errorseq=1; break 3
	fi
    done
done
rm temp3910

if test `echo "$errorseq==1" |bc -l` -eq 1; then echo errorseq > align.ali; exit; fi

#check for all in list is in align, including pm.pdb
errorfil=0
for fil in `cat list`; do
    if test `grep ":" align.ali | awk 'BEGIN{FS=":";a=0}{if($2=="'${fil}'"){a=1}}END{print a}'` -eq 0; then
	errorfil=1; break 2
    fi
done
ISPM=`grep -n pm.pdb align.ali | grep structureX | awk 'BEGIN{FS=":"}{print $1}' | head -n1`
if test -z $ISPM; then LINE2REP=`grep -n pm.pdb align.ali | grep sequence | awk 'BEGIN{FS=":"}{print $1}' | head -n1`; fi
if test -z $ISPM; then errorfil=1; fi

if test `echo "$errorfil==1" |bc -l` -eq 1; then echo errorfil > align.ali; exit; fi

