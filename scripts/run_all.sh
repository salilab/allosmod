#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

module load allosmod

LOCAL_SCRATCH=$1
GLOBAL_SCRATCH=$2

if test -e dirlist; then rm dirlist; fi

for d in `ls -1d *`; do
    if test -d $d; then 
	echo $d >>dirlist
	cd $d
	allosmod setup >> error.log
	#record input file errors
	if test -s error.log; then
	    echo 1 >error
	else
	    echo 0 >error
	fi

	if test -e glyc.dat; then
	    GLYC1=1
	else
	    GLYC1=0
	fi

	#if doing glycosylation option2, MODELLER library files will change
	GLYC2=0
	if test -e allosmod.py; then
	    GLYC2=`grep "self.patch(residue_type=" allosmod.py  | awk 'BEGIN{a=0}(NF>0){a=1}END{print a}'`
	fi

	# generate qsub.sh
	$SCRIPT_DIR/run.sh $d $SAMPLING $GLYC1 $GLYC2 $LOCAL_SCRATCH $GLOBAL_SCRATCH

	cd ..
    fi
done

echo 1 >jobcounter
