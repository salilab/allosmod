#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

#run from directory in which all runs have been collected into single directory called output (allosmod postprocessing)
PWD0=`pwd`
cd output/

#allosmod-foxs run
    cp input/saxs.dat $PWD0

    if test -s input/pm_scan_1.pdb; then
	#scanning performed
	mkdir ${PWD0}/1
	mv input/pm_scan_*.pdb ${PWD0}/1
    else
	#no scanning

        #delete unfolded structures
	PM=`head -n1 input/list | awk '{print "pm_"$1}' | awk '{print "ls -1 input/pred_dE*/*[0-9]/"$1}' | sh | head -n1`
	if test -z $PM; then PM=`ls -1 input/pred_dE*/*[0-9]/pm.pdb.B99990001.pdb | head -n1`; fi
	if (test ! -z $PM); then 
	    $SCRIPT_DIR/filter_lowq.sh $PM "input/pred_dE*/*[0-9]/pm.pdb.B[1-9]*"
#	    mkdir ${PWD0}/data; mv qscore.dat ${PWD0}/data
	    mv qscore.dat ${PWD0}
	fi

	ctr=1
	for dir in `ls -1d input/pred_dE*/*_[0-9]` `ls -1d input/pred_dE*/*_[0-9][0-9]`; do
	    if test -d $dir; then
		mkdir ${PWD0}/$ctr
		mv $dir/pm.pdb.B[1-9]*.pdb ${PWD0}/$ctr
	    fi
	    ctr=$((${ctr} + 1))
	done
    fi

    #copy error file if no structures
    NPDB=`ls -1 [0-9]`
    ERRFILS=(`ls -1 output/input/pred_*/*_0/model*log | head -n1` `ls -1 output/input/pred_*/*_0/error.log | head -n1` `ls -1 output/input/error.log | head -n1` )
    if test -z $NPDB; then
	mkdir 1/
	echo ${ERRFILS[@]} | awk '{print "cp "$0" 1/"}' |sh
    fi

    #zip only relevant structures for FoXS
    cd $PWD0
    rm output/*/scan
    zip -r output.zip [1-9] [1-9][0-9] [1-9][0-9][0-9] data
    sleep 1m
    
    #get FoXS parameters
    QMAX=`awk '($1=="qmax"){print $2}' output/input/foxs.in`
    PSIZE=`awk '($1=="psize"){print $2}' output/input/foxs.in`
    HLAYER=1 #`awk '($1=="hlayer"){print $2}' output/input/foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
    EXVOLUME=1 #`awk '($1=="exvolume"){print $2}' output/input/foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
    IHYDRG=1 #`awk '($1=="ihydrogens"){print $2}' output/input/foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
    BACKADJ=`awk '($1=="backadj"){print $2}' output/input/foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
    COARSE=`awk '($1=="coarse"){print $2}' output/input/foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
    OFFSET=0 #`awk '($1=="offset"){print $2}' output/input/foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
    EMAIL="none" # FoXS doesn't use the email parameter
    
    #run FoXS
    /usr/bin/web_service.py run https://modbase.compbio.ucsf.edu/foxs/job pdbfile=@output.zip profile=@saxs.dat q=$QMAX psize=$PSIZE hlayer=$HLAYER exvolume=$EXVOLUME ihydrogens=$IHYDRG residue=$COARSE offset=$OFFSET background=$BACKADJ >& foxs.log
    echo output.zip saxs.dat $EMAIL $QMAX $PSIZE $HLAYER $EXVOLUME $IHYDRG $COARSE $OFFSET $BACKADJ >>foxs.log
    perl -n -e '/will be found at (http.*)/ && print $1' < foxs.log > urlout
    if (test ! -s urlout); then
#	echo ...FoXS run error, please contact system administrator >urlout
	echo fail >urlout
    fi

    rm -rf [1-9] [1-9][0-9]
    rm -rf output
