set TASK = (\
)
set jobname = $TASK[$SGE_TASK_ID]

set RUNDIR=`pwd`
set MDIR=/netapp/sali/pweinkam/model
set OUTDIR=$RUNDIR/pred_dErAS/_${jobname}
ls $RUNDIR/pred_dErAS >& /dev/null
if ( $status != 0 ) then
    mkdir $RUNDIR/pred_dErAS
endif
mkdir $OUTDIR

# Get the 'allosmod' binary in the path
module load allosmod

# Make a temporary directory on the scratch disk, 
# specific to the user and SGE job.  
set TMPDIR="/scratch/pweinkam/_${jobname}_$JOB_ID/"
mkdir -p $TMPDIR
echo $TMPDIR

# Copy input files to $TMPDIR here...
awk '{print "cp "$1" '${TMPDIR}'"}' list |sh
cp align.ali $TMPDIR/align.ali
cp list $TMPDIR/
cp lig.pdb $TMPDIR/

########## do the actual job 
cd $TMPDIR
date
hostname
date >>run.log

#generate pm's
set ctr=0
foreach s (`cat list`)
    echo $s >listin
    /netapp/sali/allosmod/get_pm_initialstruct.sh align.ali listin ./ 1 slow
    awk '($1=="ATOM"||$1=="HETATM"){print $0}'  pred_${s}/pm.pdb.B99990001.pdb >pm_${s}
    if ( $ctr > 0 ) then
	/netapp/sali/allosmod/salign0.sh pm_ pm_${s}
	awk '($1=="ATOM"||$1=="HETATM"){print $0}' pm_${s}_fit.pdb >pm_${s}
    endif
    @ ctr=( ${ctr} + 1 )
end
rm listin
date >>run.log

#generate allosteric site
/netapp/sali/allosmod/get_allostericsite2.sh  lig.pdb pm_ 
cp allostericsite_/atomlistASRS .
rm -rf allostericsite_

#make average pdb 
/netapp/sali/allosmod/getavgpdb2.sh pm_ pm_ >>run.log

#get restraints
set ctr=0
head -n1 list >listin
/netapp/sali/allosmod/get_pm2.sh pm.pdb listin ini -3333 3 3 3
/netapp/sali/pweinkam/utils/modeller_v3/bin/modSVN model_ini.py
mv pm.pdb.rsr listAS.rsr
awk '(NF>0){print $0}' list >listin
/netapp/sali/allosmod/get_pm2.sh pm.pdb listin ini -3333 3 3 3
/netapp/sali/pweinkam/utils/modeller_v3/bin/modSVN model_ini.py
mv pm.pdb.rsr listOTH.rsr
/netapp/sali/allosmod/editrestraints2.sh listOTH.rsr listAS.rsr pm_ pm_ atomlistASRS 2.0,2.0,2.0 11.0   >>run.log


#initialize starting structure
set RR=`date --rfc-3339=ns | awk -F. '{print $2}' | awk -F- '{print $1}'`
set RAND_NUM=`echo "scale=0; -1*(155421*${JOB_ID}+${RR})%40000-2" |bc -l`
set RR1=`echo "scale=0; (155421*${JOB_ID}+${RR})%360" |bc -l`
set RR2=`echo "scale=0; (5433*${JOB_ID}+2*${RR})%360" |bc -l`
set RR3=`echo "scale=0; (11*${JOB_ID}+3*${RR})%360" |bc -l`
/netapp/sali/allosmod/get_pm2.sh pm.pdb list ini $RAND_NUM $RR1 $RR2 $RR3
/netapp/sali/pweinkam/utils/modeller_v3/bin/modSVN model_ini.py
allosmod setchain random.ini A | awk '($1=="ATOM"||$1=="HETATM"){print $0}' >tempini
mv tempini random.ini

#convert restraints to splines
/netapp/sali/allosmod/get_pm2.sh pm.pdb list run $RAND_NUM $RR1 $RR2 $RR3
/netapp/sali/pweinkam/utils/modeller_v3/bin/modSVN model_run.py
echo "randomized numbers: $RAND_NUM $RR1 $RR2 $RR3" >>run.log
/netapp/sali/allosmod/get_pm2.sh pm.pdb list run $RAND_NUM $RR1 $RR2 $RR3 script
#/netapp/sali/pweinkam/utils/modeller/bin/modSVN model_run.py

date
date >>run.log
ls -l *rsr >>run.log

# Copy back output files from $TMPDIR here...
rm get_pm.params
if(-e targlist) then
    rm targlist
endif
if(-e model_ini.log) then
    rm model_ini.log
endif
rm pm.pdb.rsr
rm *fit.pdb listin
rm tempdmod.in*
rm edited.rsr list*rsr

sleep 5s
mv * $OUTDIR
cd $RUNDIR
rm -rf $TMPDIR
