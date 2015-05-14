#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

################### 
#name of directories to include in foxs ensemble
JOBNAME=`pwd | awk '{print "basename "$0}' |sh`
R_JOBNAME=( $JOBNAME )
#pdb file used as reference for folding metric
PM=`head -n1 input/list | awk '{print "pm_"$1}' | awk '{print "ls -1 input/pred_dE*/*[0-9]/"$1}' | sh | head -n1`
if test -z $PM; then PM=`head -n1 input/list | awk '{print "ls -1 input/pred_dE*/*[0-9]/"$1}' | sh | head -n1`; fi
if test -z $PM; then echo error determining PM file run_foxs_ensemble.sh; exit; fi
####################

cd input/
ls -1d pred_dE*/*[0-9]/pm.pdb.B[1-9]* >list_${JOBNAME}

NUMRUN=${#R_JOBNAME[@]}

echo "jobname=${JOBNAME}" >qsub.sh

cat <<EOF >> qsub.sh

RUNDIR=\`pwd\`/input
OUTDIR=\$RUNDIR/
mkdir -p \$OUTDIR

# Make a temporary directory on the scratch disk, 
# specific to the user and SGE job.  
TMPDIR="/scratch/foxs_\${jobname}_\$JOB_ID/"
mkdir -p \$TMPDIR
echo \$TMPDIR

# Copy input files to  here...
cp \${RUNDIR}/saxs.dat \$TMPDIR/
cp \${RUNDIR}/list_\${jobname} \$TMPDIR/
cp \${RUNDIR}/foxs.in \$TMPDIR/
cp \`pwd\`/${PM} \$TMPDIR/
bnPM=\`basename $PM\`

ASPDB=\`grep -i "ASPDB" \${RUNDIR}/input.dat | awk 'BEGIN{FS="="}{print \$2}' | awk '{print \$1}'\`
awk 'BEGIN{FS="/"}{print "cp '\${RUNDIR}'/"\$0" '\${TMPDIR}/'X"\$(NF-1)"_"\$NF"X"}' \${RUNDIR}/list_\${jobname} |\
      sed "s/X\${ASPDB}_//g" | sed "s/_pm.pdb.B/_/g" | sed "s/0001.pdbX/.pdb/g" |sh
awk 'BEGIN{FS="/"}{print \$0" X"\$(NF-1)"_"\$NF"X"}' \${RUNDIR}/list_\${jobname} |\
      sed "s/X\${ASPDB}_//g" | sed "s/_pm.pdb.B/_/g" | sed "s/0001.pdbX/.pdb/g" >\${TMPDIR}/RENAME
awk 'BEGIN{FS="/"}{print "X"\$(NF-1)"_"\$NF"X"}' \${RUNDIR}/list_\${jobname} |\
      sed "s/X\${ASPDB}_//g" | sed "s/_pm.pdb.B/_/g" | sed "s/0001.pdbX/.pdb/g" >\${TMPDIR}/list_soap

########## do the actual job 
cd \$TMPDIR
hostname
date

module load sali-libraries

#get energies
$SCRIPT_DIR/get_score_soap.sh list_soap
rm list_soap

#filter unfolded and print filenames
$SCRIPT_DIR/filter_lowq.sh \${bnPM} "*.pdb"
$SCRIPT_DIR/comp_intsctn2 filenames 1 energy_soap.dat 1 | awk '{print \$1".dat "\$2}' >filenames.txt

#make profiles
$SCRIPT_DIR/get_profiles.sh \${bnPM}

#run foxs_ensemble
$SCRIPT_DIR/get_foxs_ens.sh \${jobname}
rm -rf [1-5]_1[1-9] [1-5]_[2-9][0-9] [1-5]_[1-9][0-9][0-9] #dont keep too many

#assign output structures using rmsd clustering
$SCRIPT_DIR/get_struct_cluster.sh \${bnPM}
#get structure properties of "new state"
$SCRIPT_DIR/get_ens_score_newstate.sh \${bnPM}

# Copy back output files from  here...
#rm *pdb *.plt
#rm -rf *.dat

date

sleep 5s
mv * \$OUTDIR
cd \$RUNDIR
sleep 1m
rm -rf \$TMPDIR

EOF



