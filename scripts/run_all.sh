#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

LOCAL_SCRATCH=$1
GLOBAL_SCRATCH=$2

if test -e dirlist; then rm dirlist; fi

for d in `ls -1d *`; do
    if test -d $d; then 
	echo $d >>dirlist
	cd $d
	#check for correct input files
	R_FIL=(input.dat align.ali list)
	for fil in ${R_FIL[@]}; do
	    if (test ! -e ${fil}); then
		echo "Missing file: "$fil >>error.log
	    fi
	    #get rid of odd newline problems
	    awk '{print $0}' $fil | sed 's/\o015//g' >tempra441; mv tempra441 $fil
	done
	#check input.dat
	R_INP=(NRUNS)
	for inp in ${R_INP[@]}; do
	    testvar=`grep -il "${inp}" input.dat`
	    if test -z $testvar; then 
		echo "Missing variable in input.dat: "$inp >>error.log
	    fi
	    testvar=`grep -i "${inp}" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}' | grep -E "^[0-9.]+$"`
	    if test -z $testvar; then
                echo "Invalid variable in input.dat: "$inp >>error.log
            fi
	done
	#check list
	for fil in `cat list`; do
	    if (test ! -e ${fil}); then
                echo "Missing file: "$fil >>error.log
            fi
	    testvar=`grep -il "${fil}" align.ali`
	    if test -z $testvar; then
		echo "Missing sequence in align.ali for file: "$fil >>error.log
	    fi
	done
	#check alignment
	R_FIL=(`grep ">" align.ali | awk '{print NR}'`)
	ctr=0
	MAXi=0
	for i1 in ${R_FIL[@]}; do
	    ctr=$((${ctr} + 1))
	    S1=(`grep -n ">" align.ali |awk -F: '(NR=='${i1}'){printf $1+2" "}(NR=='${i1}'+1){printf $1-1" "}' |\
                 awk '(NF<=0){print "ERROR"}(NF==2){print $0}(NF==1){printf $0$1+999"\n"}'`)
	    NUMi=`awk 'BEGIN{FS="";a=0}(NR>='${S1[0]}'&&NR<='${S1[1]}'){a+=NF}END{print a}' align.ali`
	    tMAXi=`cat align.ali | sed "s/-//g" | sed "s/\///g" | sed "s/*//g" |\
                   awk 'BEGIN{FS="";a=0}(NR>='${S1[0]}'&&NR<='${S1[1]}'){a+=NF}END{print a}'`
	    if test `echo "${tMAXi}>${MAXi}" |bc -l` -eq 1; then MAXi=${tMAXi}; fi
	    if test `echo "${ctr}>1" |bc -l` -eq 1; then
		if test `echo "${NUMi}!=${lastNUMi}" |bc -l` -eq 1; then
		    echo "Sequences in align.ali are not properly aligned" >>error.log
		fi
		break
	    fi
	    lastNUMi=$NUMi
	done
	testvar=`grep -il pm.pdb align.ali | head -n1`
	if test -z $testvar; then
	    echo "Missing sequence in align.ali for file: pm.pdb" >>error.log
	fi

	#record input file errors
	if test -e error.log; then
	    echo 1 >error
	else
	    echo 0 >error
	fi

################ modify input files for type of run ################

	#if no lig.pdb, use center of mass
	if (test ! -e lig.pdb); then 
	    PDB=`head -n1 list`
	    awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){{for(a=31;a<=38;a++){printf $a}}{printf " "}\
                 {for(a=39;a<=46;a++){printf $a}}{printf " "}\
                 {for(a=47;a<=54;a++){printf $a}}{printf " \n"}}' $PDB |\
                 awk 'BEGIN{a=0;b=0;c=0}{a+=$1;b+=$2;c+=$3}END\
                 {printf "ATOM      1  XX  ALA A   1    %8.3f%8.3f%8.3f  1.00 99.99           C\n",a/NR,b/NR,c/NR}' >lig.pdb
	fi

	#if no delEmax specified, determine during calculation
	testvar=`grep -il "delEmax" input.dat`
	if test -z $testvar; then
	    echo delEmax=CALC >>input.dat
	else
	    testvar=`grep -i "delEmax" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
	    if test -z $testvar -o $testvar == "CALC"; then
		grep -iv "delEmax" input.dat >tempi1
		mv tempi1 input.dat
		echo delEmax=CALC >>input.dat
	    else
		testvar=`grep -i "delEmax" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}' | grep -E "^[0-9.]+$"`
		if test -z $testvar; then
		    echo "Invalid variable in input.dat: delEmax" >>error.log
		fi
	    fi
	fi

	#if no LIGPDB specified, use top of list
	testvar=`grep -il "LIGPDB" input.dat`
	if test -z $testvar; then
	    LPDB=`head -n1 list`
	    echo LIGPDB=${LPDB} >>input.dat
	else
	    testvar=`grep -i "LIGPDB" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
	    if test -z $testvar; then
		grep -iv "LIGPDB" input.dat >tempi1
		mv tempi1 input.dat
		LPDB=`head -n1 list`
		echo LIGPDB=${LPDB} >>input.dat
	    fi
	fi
	testvar=`grep -il "${LIGPDB}" align.ali`
	if test -z $testvar; then
	    echo "Missing LIGPDB in align.ali for file: "$LIGPDB >>error.log
	fi

	#if no ASPDB specified, use top of list
	testvar=`grep -il "ASPDB" input.dat`
	if test -z $testvar; then
	    APDB=`head -n1 list`
	    echo ASPDB=${APDB} >>input.dat
	else
	    testvar=`grep -i "ASPDB" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
	    if test -z $testvar; then
		grep -iv "ASPDB" input.dat >tempi1
		mv tempi1 input.dat
		APDB=`head -n1 list`
		echo ASPDB=${APDB} >>input.dat
	    fi
	fi
	testvar=`grep -il "${ASPDB}" align.ali`
	if test -z $testvar; then
	    echo "Missing ASPDB in align.ali for file: "$ASPDB >>error.log
	fi
	
	#if no deviation specified, set to default 1 Angstrom
	testvar=`grep -il "DEVIATION" input.dat`
	if test -z $testvar; then
	    echo DEVIATION=1.0 >>input.dat
	else
	    testvar=`grep -i "DEVIATION" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
	    if test -z $testvar; then
		grep -iv "DEVIATION" input.dat >tempi1
		mv tempi1 input.dat
		echo DEVIATION=1.0 >>input.dat
	    else
		testvar=`grep -i "DEVIATION" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}' | grep -E "^[0-9.]+$"`
		if test -z $testvar; then
		    echo "Invalid variable in input.dat: DEVIATION" >>error.log
		fi
	    fi
	fi

	#if no rAS specified, set to default 1000 Angstroms
	testvar=`grep -il "rAS" input.dat`
	if test -z $testvar; then
	    echo rAS=1000 >>input.dat
	else
	    testvar=`grep -i "rAS" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
	    if test -z $testvar; then
		grep -iv "rAS" input.dat >tempi1
		mv tempi1 input.dat
		echo rAS=1000 >>input.dat
	    else
		testvar=`grep -i "rAS" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}' | grep -E "^[0-9.]+$"`
		if test -z $testvar; then
		    echo "Invalid variable in input.dat: rAS" >>error.log
		fi
	    fi
	fi

	#test for sampling type: 1) simulation, 2) moderate_cm, 3) moderate_am
	testvar=`grep -il "SAMPLING" input.dat`
	if test -z $testvar; then
	    echo SAMPLING=simulation >>input.dat
	    SAMPLING=simulation
	else
	    testvar=`grep -i "SAMPLING" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
	    if test -z $testvar; then
		grep -iv "SAMPLING" input.dat >tempi1
		mv tempi1 input.dat
		echo SAMPLING=simulation >>input.dat
		SAMPLING=simulation
	    else
		testvar=`grep -i "SAMPLING" input.dat | awk 'BEGIN{FS="="}{print $2}' |\
                         awk '($1=="simulation"||$1="moderate_cm"||$1="moderate_am"){print "OK"}'`
		SAMPLING=`grep -i "SAMPLING" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`
		if test -z $testvar; then
		    echo "Invalid variable in input.dat: SAMPLING" >>error.log
		    SAMPLING=simulation
		fi
	    fi
	fi
	

	#if doing glycosylation option1, set sampling to moderate_cm
	if test -e glyc.dat; then
	    GLYC1=1
	    if test $SAMPLING != "moderate_cm"; then
		SAMPLING=moderate_cm
		echo "" >SAMPLING_set_to_moderate_cm_for_glycosylation
		grep -iv "SAMPLING" input.dat >tempi1; mv tempi1 input.dat
		echo SAMPLING=moderate_cm >>input.dat
	    fi
	    #no deviation if glycosylation
	    grep -iv "DEVIATION" input.dat >tempi1; mv tempi1 input.dat
	    echo DEVIATION=0.0 >>input.dat
	else
	    GLYC1=0
	fi

	#if doing glycosylation option2, MODELLER library files will change
	GLYC2=0
	if test -e allosmod.py; then
	    GLYC2=`grep "self.patch(residue_type=" allosmod.py  | awk 'BEGIN{a=0}(NF>0){a=1}END{print a}'`
	fi

	#if list has one structure, force rAS=1000
	LEN_LIST=`awk '(NF>0){a+=1}END{print a}' list`
	if test $SAMPLING != "moderate_cm"; then
	    if test `echo "${LEN_LIST}==1" |bc -l` -eq 1; then 
		#cat list list >tempra5541; mv tempra5541 list
		grep -iv "rAS" input.dat >tempi1; mv tempi1 input.dat; echo rAS=1000 >>input.dat
		#grep -iv "DEVIATION" input.dat >tempi1; mv tempi1 input.dat; echo DEVIATION=10 >>input.dat
	    fi
	fi

	#if number_residues >1500, use coarse landscape
	if test `echo "${MAXi}>1500" |bc -l` -eq 1; then
	    grep -iv "COARSE" input.dat >tempi1; mv tempi1 input.dat; echo COARSE=True >>input.dat
	fi

	# generate qsub.sh
	$SCRIPT_DIR/run.sh $d $SAMPLING $GLYC1 $GLYC2 $LOCAL_SCRATCH $GLOBAL_SCRATCH

	cd ..
    fi
done

echo 1 >jobcounter
