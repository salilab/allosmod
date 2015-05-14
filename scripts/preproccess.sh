#!/bin/bash

if test -e dirlist; then #after first pass
    len=`awk 'END{print NR}' dirlist`
    if test `echo "${len}>1" |bc -l` -eq 1; then
	awk '(NR>1){print $0}' dirlist >temppp4451; mv temppp4451 dirlist
	iJOB=`cat jobcounter`
	echo $iJOB | awk '{print $1+1}' >jobcounter
    else
	echo -1 >jobcounter
    fi
else #first pass
    ctr=0
    for d in `ls -1d *`; do
	if test -d $d; then
	    ctr=$((${ctr} + 1))
	fi
    done
    if test `echo "${ctr}>1" |bc -l` -eq 1; then
	echo 1 >jobcounter
    else
	echo -99 >jobcounter
    fi
fi