#!/bin/bash 
# 1) FILE1 2) FILE2
# Fits using either P or CA depending on which is more in FF1

FF1=$1
FF2=$2

NCA=`awk 'BEGIN{FS="";a=0}($14$15=="CA"){a+=1}END{print a}' $FF1`
NP=`awk 'BEGIN{FS="";a=0}($14$15=="P "){a+=1}END{print a}' $FF1`
if test `echo "${NCA}>=${NP}" |bc -l` -eq 1; then
    OPT=CA
else
    OPT=P
fi

#if (test ! -e tempdmod.in); then
cat <<EOF >tempdmod.in

from modeller import *

log.verbose()
env = environ()
env.io.atom_files_directory = ['.', '../atom_files']

# Read in HETATM records from template PDBs
env.io.hetatm = True

mdl = model(env)
aln = alignment(env)

#for (code) in ('$FF1', '$FF2'):
code='$FF1'
mdl.read(file=code, model_segment=('FIRST:@', 'END:'))
aln.append_model(mdl, atom_files=code, align_codes=code)
code='$FF2'
mdl.read(file=code, model_segment=('FIRST:@', 'END:'))
aln.append_model(mdl, atom_files=code, align_codes=code)

for (weights, write_fit, whole) in (((1., 0., 0., 0., 1., 0.), False, True),
                                    ((1., 0.5, 1., 1., 1., 0.), False, True),
                                    ((1., 1., 1., 1., 1., 0.), True, False)):
    aln.salign(rms_cutoff=3.5, normalize_pp_scores=False,
               rr_file='\$(LIB)/as1.sim.mat', overhang=30,
               gap_penalties_1d=(-450, -50),
               gap_penalties_3d=(0, 3), gap_gap_score=0, gap_residue_score=0,
               dendrogram_file='temp5773.tree', fit_atoms='${OPT}',
               alignment_type='tree', # If 'progresive', the tree is not
                                      # computed and all structues will be
                                      # aligned sequentially to the first
               #ext_tree_file='1is3A_exmat.mtx', # Tree building can be avoided
                                                 # if the tree is input
               feature_weights=weights, # For a multiple sequence alignment only
                                        # the first feature needs to be non-zero
               improve_alignment=True, fit=True, write_fit=write_fit,
               write_whole_pdb=whole, output='ALIGNMENT QUALITY')

# aln.write(file='2g75.pap', alignment_format='PAP')
aln.write(file='temp5773.ali', alignment_format='PIR')

# The number of equivalent positions at different RMS_CUTOFF values can be
# computed by changing the RMS value and keeping all feature weights = 0
#aln.salign(rms_cutoff=1.0,
#           normalize_pp_scores=False, rr_file='\$(LIB)/as1.sim.mat', overhang=30,
#           gap_penalties_1d=(-450, -50), gap_penalties_3d=(0, 3), fit_atoms='${OPT}',
#           gap_gap_score=0, gap_residue_score=0, dendrogram_file='temp5773.tree',
#           alignment_type='progressive', feature_weights=[0]*6,
#           improve_alignment=False, fit=False, write_fit=True,
#           write_whole_pdb=False, output='QUALITY')
EOF
#fi

/salilab/diva1/home/modeller/modSVN tempdmod.in

#print out strict equivlence
#SCOR=`grep percentage tempdmod.in.log  |awk '(NR==4){print $4}'`  
#SI=`./get_percid.sh temp5773.ali`
#echo "quality percentage: " $SCOR
#echo "QS, %SI: " $FF1 $FF2 $SCOR $SI

#rm tempdmod.in tempdmod.in.log
#rm temp5773.ali
