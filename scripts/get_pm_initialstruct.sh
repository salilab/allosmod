#!/bin/bash
#makes comparative model from a sequence
#SLIST are templates, target taken from: 1) if OPT, then entry named OPT, 2) if no OPT, first entry in AFIL
#DEFAULT: templates must be very similar to target! (>50%) since automatic seq alignment performed, to abstain set OPT2
#OPT3 set to exit upon making restraint file

AFIL=$1
SLIST=$2
PDIR=$3
NMODEL=$4 #fix number format it > 10
REFINE_LEVEL=$5
OPT=$6
OPT2=$7
OPT3=`echo $8 | awk 'BEGIN{FS="";a=""}(NF>0){a="exit_stage=1"}END{print a}'`

#get pdb files
if test -z $OPT; then
    F[0]=`awk 'BEGIN{FS=";"}(NF>1){print $2;exit}' $AFIL`
else
    F[0]=$OPT
fi
NFIL=`awk 'END{print NR}' $SLIST`
RANGEY=`/netapp/sali/allosmod/count.pl 1 $NFIL`
for y in $RANGEY; do
    F[$y]=`awk '(NR=='$y'){print $1}' $SLIST`
done

#random number
RR1=`date --rfc-3339=ns | awk -F. '{print $2}' | awk -F- '{print $1/1000}'`
RR2=`date --rfc-3339=ns | awk -F: '{print $3}' | awk -F. '{print $1}'`
RAND_NUM=`echo "scale=0; -1*(${RR1}*${RR2}*11)%40000-2" |bc -l | awk '{printf "%9.0f",$1}' | awk '{print $1}'`

if test -e pred_${F[1]}; then 
    echo "pred_${F[$y]} exists, overwriting"
else
    mkdir pred_${F[1]}
fi
for y in $RANGEY; do
    cp ${PDIR}/${F[$y]} pred_${F[1]}
done
cp ${AFIL} pred_${F[1]}
cd pred_${F[1]}

#if no hetatm in template, delete hetatms
NSTRT=`grep -n pm.pdb ${AFIL} | awk 'BEGIN{FS=":"}{print $1;exit}'`
isHET1=`awk 'BEGIN{FS="";isHET=0}{for(a=1;a<=NF;a++){if(NR>'${NSTRT}'+1&&($a=="."||$a=="h")){isHET=1}if(NR>'${NSTRT}'+1&&$a=="*"){exit}}}END{print isHET}' ${AFIL}`
NSTRT=`grep -n ${F[1]} ${AFIL} | awk 'BEGIN{FS=":"}{print $1;exit}'`
isHET2=`awk 'BEGIN{FS="";isHET=0}{for(a=1;a<=NF;a++){if(NR>'${NSTRT}'+1&&($a=="."||$a=="h")){isHET=1}if(NR>'${NSTRT}'+1&&$a=="*"){exit}}}END{print isHET}' ${AFIL}`
if test `echo "${isHET1}==1 && ${isHET2}==0" |bc -l` -eq 1; then
    awk 'BEGIN{FS=""}{for(a=1;a<=NF;a++){if($a==">"){tit=1}if(tit<3||$a!="."){printf $a}\
         if(a==NF){tit+=1;printf "\n"}}}(NF==0){printf "\n"}' ${AFIL} > tempiq4
    mv tempiq4 ${AFIL}
fi

#make template using automodel, 1st structure
cat <<EOF >model_ini0.py
from modeller import *
from modeller.automodel import *
from modeller.scripts import complete_pdb

env = environ(rand_seed=${RAND_NUM})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True

a = automodel(env, deviation=None, alnfile='${AFIL}',
EOF

#add multiple templates if needed
echo -n "knowns=('${F[1]}'" >>model_ini0.py
for y in `/netapp/sali/allosmod/count.pl 2 ${NFIL}`; do # these knowns do nothing if restraint file specified
    echo -n "," >>model_ini0.py
    echo -n "'${F[$y]}'" >>model_ini0.py
done
echo -n "), sequence='${F[0]}')" >>model_ini0.py
echo >>model_ini0.py

cat <<EOF >>model_ini0.py
a.library_schedule = autosched.normal
a.md_level = refine.${REFINE_LEVEL}
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = ${NMODEL}
a.auto_align()                      # get an automatic alignment
a.make(${OPT3})

# read model file and Assess all atoms with DOPE: 
#ctr=1
#for i in range(${NMODEL}):
#     if ctr < 10:
#         mdl = complete_pdb(env, '${F[0]}.B9999000%s.pdb' % ctr)
#         s = selection(mdl)
#         outff='000' + str(ctr) + '.profile'
#         s.assess_dope(output='ENERGY_PROFILE NO_REPORT', file=outff,
#                       normalize_profile=True, smoothing_window=15)
#         ctr=ctr+1
#    else:
#         mdl = complete_pdb(env, '${F[0]}.B999900%s.pdb' % ctr)
#         s = selection(mdl)
#         outff='00' + str(ctr) + '.profile'
#         s.assess_dope(output='ENERGY_PROFILE NO_REPORT', file=outff,
#                       normalize_profile=True, smoothing_window=15)
#         ctr=ctr+1
EOF

if (test ! -z $OPT2); then
    cat model_ini0.py | sed "s/a.auto_align/#a.auto_align/g" >tempgpi5961; mv tempgpi5961 model_ini0.py
fi

#/netapp/sali/pweinkam/utils/modeller/bin/modSVN model_ini0.py
/salilab/diva1/home/modeller/modSVN model_ini0.py

#fill in missing chain if necessary
if test -z $OPT3; then
    CHAIN=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $22$23}' ${F[0]}.B99990001.pdb | awk '{print $1}' | sort -u | head -n1`
    if test -z $CHAIN; then
	NC=`grep ${F[0]} ${AFIL} | grep -v P1 | awk 'BEGIN{FS=":"}{print $4}' | awk 'BEGIN{a="A"}(NR==1){a=$1}{print a}'`
	/netapp/sali/allosmod/setchainX ${F[0]}.B99990001.pdb $NC >tempgpi49501
	mv tempgpi49501 ${F[0]}.B99990001.pdb
    fi
fi

cd ..

