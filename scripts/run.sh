#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

###################
rAS=`grep -i "rAS" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'`   #radius of allosteric site
delEmax=`grep -i "delEmax" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'` #energy difference between global minima and max E 
                                                                         #for a truncated Gaussian distance restraint (kcal/mol), 
                                                                         #set to zero to use multi_gaussian instead
NRUNS=`grep -i "NRUNS" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'` #number of runs
LIGPDB=`grep -i "LIGPDB" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'` #pdb file from which ligand is bound to
ASPDB=`grep -i "ASPDB" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'` #pdb file to define AS distance interactions
OTHERPDB=`awk 'BEGIN{a="'${ASPDB}'"}($1!="'${ASPDB}'"){a=$1;exit}END{print a}' list`
DEV=`grep -i "DEVIATION" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk '{print $1}'` #number of angstroms to randomize starting structure after interpolating between basins
MDTEMP=`grep -i "MDTEMP" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a=300.0}{a=$1}END{print a}' | tr [A-Z] [a-z]` #option to change simulation temperature
REP_OPT=`grep -i "repeat_optimization" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a=1}{a=$1}END{print a}'` #option to change repeat optimization for model_glyc.py
ATT_GAP=`grep -i "attach_gaps" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a="True"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #insert gaps for glyc attach sites
SCRAPP=`grep -i "SCRAPP" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a="False"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #move output to global scratch
DIR=$1
SAMPLING=$2
GLYC1=$3
GLYC2=$4
LOCAL_SCRATCH=$5
GLOBAL_SCRATCH=$6

BREAK=`grep -i "BREAK" input.dat | grep -v "SCLBREAK" | awk 'BEGIN{FS="="}{print $2}' |\
       awk 'BEGIN{a="False"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #break dist interactions for buried charged res
SCLBREAK=`grep -i "SCLBREAK" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a=0.1}{a=$1}END{print a}'` #if break, contacts scaled by SCLBREAK
ZCUTOFF=`grep -i "ZCUTOFF" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a=3.5}{a=$1}END{print a}'` #if break, contacts broken w res that have z-score > ZCUTOFF
CHEMFR=`grep -i "CHEMFR" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a="cdensity"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #if break, type of chemical frustration
COARSE=`grep -i "COARSE" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a="False"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #coarse grained, only CA/CB for dist interaction
LOCRIGID=`grep -i "LOCALRIGID" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a="False"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #increase local rigidity
testmode=`grep -i "PW" input.dat | awk 'BEGIN{FS="="}{print $2}' | awk 'BEGIN{a="False"}{a=$1}END{print a}' | tr [A-Z] [a-z]` #run test code
####################
if [ "${COARSE}" = "true" ]; then
  COARSE="--coarse"
else
  COARSE=""
fi
if [ "${LOCRIGID}" = "true" ]; then
  LOCRIGID="--locrigid"
else
  LOCRIGID=""
fi

RANGE_LETT=( `echo $NRUNS | awk '{for(a=0;a<$1;a++){print a}}'` ) #indep runs with different starting structures

ARRAY_NAME=`date | awk '{print $2"."$3"."$4}' | sed "s/:/./g"`
NUMRUN=${#RANGE_LETT[@]}

if test -s numsim; then 
    L_NUMRUN=`cat numsim`
    echo 1 | awk '{print '${NUMRUN}'+'${L_NUMRUN}'}' >numsim
else
    echo $NUMRUN >numsim
fi

echo "TASK=( null \\" >qsub.sh

for NAME in ${RANGE_LETT[@]}; do
    echo "${NAME} \\" >>qsub.sh
done
echo ")" >>qsub.sh
echo "jobname=\${TASK[\$SGE_TASK_ID]}" >>qsub.sh

echo "cd "$DIR >>qsub.sh

cat $SCRIPT_DIR/input_qsub.sh | sed "s/DDD/pred_dE${delEmax}rAS${rAS}/g" | sed "s/XASPDB/${ASPDB}/g" | sed "s/XOTHPDB/${OTHERPDB}/g" \
    | sed "s^@LOCAL_SCRATCH@^$LOCAL_SCRATCH^g" \
    | sed "s^@GLOBAL_SCRATCH@^$GLOBAL_SCRATCH^g" \
    | sed "s^@SCRIPT_DIR@^$SCRIPT_DIR^g" \
    | sed "s/XdE/${delEmax}/g" | sed "s/XrAS/${rAS}/g" | sed "s/XLPDB/${LIGPDB}/g" | sed "s/XDEV/${DEV}/g" \
    | sed "s/XSAMP/${SAMPLING}/g" | sed "s/XGLYC1/${GLYC1}/g" | sed "s/XREP_OPT/${REP_OPT}/g" | sed "s/XMDTEMP/${MDTEMP}/g" \
    | sed "s/XATT_GAP/${ATT_GAP}/g" | sed "s/XBREAK/${BREAK}/g" | sed "s/XSCRAPP/${SCRAPP}/g" | sed "s/XCOARSE/${COARSE}/g" \
    | sed "s/XLOCRIGID/${LOCRIGID}/g" | sed "s/XSCLBREAK/${SCLBREAK}/g" | sed "s/XZCUTOFF/${ZCUTOFF}/g" | sed "s/XCHEMFR/${CHEMFR}/g" \
    | sed "s/XGLYC2/${GLYC2}/g" >>qsub.sh

#determine if AllosMod-FoXS run
if test $testmode == "true"; then
    if test -s saxs.dat; then
	echo 1 >allosmodfox #AllosMod-FoXS run
    else
	echo 0 >allosmodfox #not AllosMod-FoXS run
    fi
else
    echo 0 >allosmodfox
fi
##echo 0 >scan #no scan

