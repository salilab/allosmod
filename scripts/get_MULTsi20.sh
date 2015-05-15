#!/bin/bash
#find si between pdbs in list

# Get the 'allosmod' binary in the path
module load allosmod

S1=`grep -n pm.pdb align.ali | awk 'BEGIN{FS=":"}(NR==1){print $1}'`
SE=`awk 'END{print NR}' align.ali`
S2=`grep -n P1 align.ali | awk 'BEGIN{FS=":";a='${S1}';b=-1}($1>a){b=$1-1;exit}END{if(b==-1){print '${SE}'}else{print b}}'`

awk '(NR>='${S1}'&&NR<='${S2}'){print $0}' align.ali >tempms004.ali
for fil in `cat list`; do
    allosmod pdb2ali $fil >>tempms004.ali
done

cat <<EOF >modeller.in
from modeller import *
log.verbose()
env = environ()
env.io.atom_files_directory = ['.', '../atom_files']

aln = alignment(env)
aln.append(file='tempms004.ali', align_codes=('pm.pdb'
EOF

for fil in `cat list`; do
    echo -n ",'"$fil"'" >>modeller.in
done
echo "))" >>modeller.in

#echo "# The as1.sim.mat similarity matrix is used by default:" >>modeller.in
#echo "aln.align(gap_penalties_1d=(-600, -400))" >>modeller.in
echo "aln.salign(overhang=30, gap_penalties_1d=(-450, -50)," >>modeller.in
echo "alignment_type='tree', output='ALIGNMENT')" >>modeller.in
echo "aln.write(file='align_suggested.ali')" >>modeller.in


/salilab/diva1/home/modeller/modSVN modeller.in


rm tempms004.ali modeller.in modeller.in.log
