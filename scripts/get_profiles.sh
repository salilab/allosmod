#!/bin/bash
#computes SAXS profiles for trajectory snapshots and input state

PM=$1 #name of initial pm file

R_PDB=( $PM `ls -1 [0-9]*.pdb` )

QMAX=`awk '($1=="qmax"){print $2}' foxs.in`
PSIZE=`awk '($1=="psize"){print $2}' foxs.in`
#HLAYER=`awk '($1=="hlayer"){print $2}' foxs.in | sed "s/on/1/g" | sed "s/off/0/g"` #not allowed to turn off for ensemble enumeration
#EXVOLUME=`awk '($1=="exvolume"){print $2}' foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
#IHYDRG=`awk '($1=="ihydrogens"){print $2}' foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
BACKADJ=`awk '($1=="backadj"){print $2}' foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`
COARSE=`awk '($1=="coarse"){print $2}' foxs.in | sed "s/on/true/g" | sed "s/off/false/g"`

for pdb in ${R_PDB[@]}; do

    # todo: update to use foxs from recent IMP instead
    /netapp/sali/dina/foxs/bin/foxs $pdb -p -q ${QMAX} -s ${PSIZE} -b ${BACKADJ} -r ${COARSE}

done
