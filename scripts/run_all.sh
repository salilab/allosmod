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
        # Make qsub.sh script
	allosmod setup >> error.log
	#record input file errors
	if test -s error.log; then
	    echo 1 >error
	else
	    echo 0 >error
            NRUNS=`grep -i "NRUNS" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'` #number of runs
            if test -s numsim; then
                L_NUMRUN=`cat numsim`
                echo 1 | awk '{print '${NUMRUN}'+'${L_NUMRUN}'}' >numsim
            else
                echo $NUMRUN >numsim
            fi
	fi

	cd ..
    fi
done

echo 1 >jobcounter
