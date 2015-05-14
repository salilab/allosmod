#!/bin/bash
#checks for atoms overlapping, e.g. dist < rcut

PDB_FIL=$1
RCUT=0.9

R_RTYPE=( PHE HIS TYR TRP HID HIE HIP HSD HSE HSP ) 

for rtype in ${R_RTYPE[@]}; do
    awk 'BEGIN{FS=""}($18$19$20=="'${rtype}'"){print $0}' $PDB_FIL >tempcao031.pdb

    echo tempcao031.pdb >targlist
    awk 'END{print NR}' tempcao031.pdb >>targlist
    echo 99 >>targlist

    /netapp/sali/allosmod/getcont_allatom | awk '($8<'${RCUT}'){print "atom overlap in '${PDB_FIL}' involving residues: "$5,$1,$6,$3,$8}'
done


rm tempcao031.pdb
