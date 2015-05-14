#!/bin/bash
#LIST format: pdb,chain,sres,eres
#top is target seq, followed by templates

TARG_SEQ=$1
LIST_KNOWNS=$2
RUNTYPE=$3 #ini, iniNUC, or run: ini outputs structure and restraint files, no CG/MD; run inputs initial structure and restraint files, then runs CG/MD
RAND=$4 #random seed
RAND_R1=$5 #random rotation angles
RAND_R2=$6
RAND_R3=$7
DEVIATION=$8
OPT=$9

# get pdb file names/chains
NFIL=`cat ${LIST_KNOWNS} |awk 'END{print NR-1}'`
F=(`cat ${LIST_KNOWNS}`)

# generate MODELLER input files
if test $RUNTYPE = "ini"; then


cat <<EOF > model_${RUNTYPE}.py
from modeller import *
from modeller.automodel import *
from modeller.scripts import complete_pdb

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

mdl = complete_pdb(env, 'avgpdb.pdb')

# Act on all atoms in the model
sel = selection(mdl)

# Change all existing X,Y,Z for +- dev:
sel.rotate_mass_center([0,0,1], ${RAND_R1})
sel.rotate_mass_center([0,1,0], ${RAND_R2})
sel.rotate_mass_center([1,0,0], ${RAND_R3})
sel.randomize_xyz(deviation=${DEVIATION})
mdl.write(file='random.ini')

a = automodel(env, deviation=None, alnfile='align.ali',
EOF
echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo "a.make(exit_stage=1)" >>model_${RUNTYPE}.py

#longer restraints for nucleic acids
elif test $RUNTYPE = "iniNUC"; then


cat <<EOF > model_ini.py
from modeller import *
from modeller.automodel import *
from modeller.scripts import complete_pdb

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

mdl = complete_pdb(env, 'avgpdb.pdb')

# Act on all atoms in the model
sel = selection(mdl)

# Change all existing X,Y,Z for +- dev:
sel.rotate_mass_center([0,0,1], ${RAND_R1})
sel.rotate_mass_center([0,1,0], ${RAND_R2})
sel.rotate_mass_center([1,0,0], ${RAND_R3})
sel.randomize_xyz(deviation=${DEVIATION})
mdl.write(file='random.ini')

class MyModel (automodel):
    max_ca_ca_distance = 14.0
    max_n_o_distance   = 11.0
    max_sc_mc_distance =  5.5
    max_sc_sc_distance = 14.0
    def distance_restraints(self, atmsel, aln):
        """Construct homology-derived distance restraints"""
        rsr = self.restraints
        # Only do the standard residue types for CA, N, O, MNCH, SDCH dst rsrs
        # (no HET or BLK residue types):

        stdres = atmsel.only_std_residues()
        calpha = stdres.only_atom_types('CA')
        nitrogen = stdres.only_atom_types('N')
        oxygen = stdres.only_atom_types('O')
        mainchain = stdres.only_mainchain()
        sidechain = stdres - mainchain

        for (dmodel, maxdis, rsrrng, rsrsgn, rsrgrp, sel1, sel2, stdev) in \\
            ((5, self.max_ca_ca_distance, (2, 99999), True,
              physical.ca_distance, calpha, calpha, (0, 1.0)),
             (6, self.max_n_o_distance,   (2, 99999), False,
              physical.n_o_distance, nitrogen, oxygen, (0, 1.0)),
             (6, self.max_sc_mc_distance, (1, 2), False,
              physical.sd_mn_distance, sidechain, mainchain, (0.5, 1.5)),
             (6, self.max_sc_sc_distance, (2, 99999), True,
              physical.sd_sd_distance, sidechain, sidechain, (0.5, 2.0))):
            if len(sel1) > 0 and len(sel2) > 0:
                rsr.make_distance(sel1, sel2, aln=aln,
                                  spline_on_site=self.spline_on_site,
                                  distance_rsr_model=dmodel,
                                  restraint_group=rsrgrp,
                                  maximal_distance=maxdis,
                                  residue_span_range=rsrrng,
                                  residue_span_sign=rsrsgn,
                                  restraint_stdev=stdev, spline_range=4.0,
                                  spline_dx=0.7, spline_min_points=5)

a = MyModel(env, deviation=None, alnfile='align.ali',
EOF
echo -n "knowns=('${F[0]}'" >>model_ini.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_ini.py
echo "), sequence='${TARG_SEQ}')" >>model_ini.py
echo "a.make(exit_stage=1)" >>model_ini.py


elif test $RUNTYPE = "run"; then

if test $OPT == "convert"; then

cat <<EOF >model_${RUNTYPE}.py
from modeller import *
from modeller.automodel import *
from modeller.scripts import complete_pdb

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

# Give less weight to all soft-sphere restraints:
#env.schedule_scale = physical.values(default=0.1)
#env.io.atom_files_directory = ['.', '../atom_files']

a = automodel(env, inifile  = 'random.ini', deviation=None, alnfile='align.ali', 
EOF

echo "MDtemp=300.0, tmstep=3.0, incmov=10, incequil=2, nmov=20, cap_atom_shift=.0829598000, convert_restraints=True, write_intermediates=True, " >>model_${RUNTYPE}.py
echo "csrfile  = 'edited.rsr', " >>model_${RUNTYPE}.py
echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo >>model_${RUNTYPE}.py

cat <<EOF >>model_${RUNTYPE}.py
# Very thorough VTFM optimization:
a.library_schedule = autosched.MDnone
a.max_var_iterations = 500

# MD optimization:
a.md_level = refine.none

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

elif test $OPT == "script"; then

cat <<EOF >model_${RUNTYPE}.py
from modeller import *
from modeller.scripts import complete_pdb
import allosmod

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

a = allosmod.AllosModel(env, inifile  = 'random.ini', deviation=None, alnfile='align.ali', 
EOF

echo -n "csrfile  = 'converted.rsr', " >>model_${RUNTYPE}.py
echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo >>model_${RUNTYPE}.py

cat <<EOF >>model_${RUNTYPE}.py
# Very thorough VTFM optimization:
a.library_schedule = allosmod.MDopt
a.max_var_iterations = 500

# MD optimization:
a.md_level = allosmod.consttemp

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

elif test $OPT == "script_glyc"; then

cat <<EOF >model_${RUNTYPE}.py
from modeller import *
from modeller.scripts import complete_pdb
import allosmod

env =environ(rand_seed=${RAND}, restyp_lib_file='/CHANGE_PATH/restyp.dat', copy=None)

# Read in HETATM records from template PDBs
env.io.atom_files_directory = ['.', '../atom_files']
env.libs.topology.read(file='/CHANGE_PATH/top_all_glyco.lib')
env.libs.parameters.read(file='/CHANGE_PATH/par_all_glyco.lib')
env.io.hetatm = True
env.io.hydrogen = True

a = allosmod.AllosModel(env, inifile  = 'random.ini', csrfile='converted.rsr', deviation=None, alnfile='align2.ali', 
EOF

echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo >>model_${RUNTYPE}.py

cat <<EOF >>model_${RUNTYPE}.py
# Very thorough VTFM optimization:
a.library_schedule = allosmod.MDopt
a.max_var_iterations = 500

# MD optimization:
a.md_level = allosmod.consttemp

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

elif test $OPT == "moderate_cm" -o $OPT == "moderate_cm_simulation"; then
#deviation set here because cm sampling does not include randomized structure
cat <<EOF >model_${RUNTYPE}.py
from modeller import *
from modeller.scripts import complete_pdb
import allosmod

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

a = allosmod.AllosModel(env, deviation=${DEVIATION}, alnfile='align.ali', 
EOF

echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo >>model_${RUNTYPE}.py

cat <<EOF >>model_${RUNTYPE}.py
# Very thorough VTFM optimization:
a.library_schedule = allosmod.MDopt
a.max_var_iterations = 500

# MD optimization:
a.md_level = allosmod.moderate

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

elif test $OPT == "fast_cm" -o $OPT == "fast_cm_simulation"; then
#deviation set here because cm sampling does not include randomized structure
cat <<EOF >model_${RUNTYPE}.py
from modeller import *
from modeller.automodel import *
from modeller.scripts import complete_pdb

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

a = automodel(env, deviation=${DEVIATION}, alnfile='align.ali', 
EOF

echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo >>model_${RUNTYPE}.py

cat <<EOF >>model_${RUNTYPE}.py
# Very thorough VTFM optimization:
a.library_schedule = autosched.normal
a.max_var_iterations = 500

# MD optimization:
a.md_level = refine.fast

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

elif test $OPT == "moderate_am"; then

cat <<EOF >model_${RUNTYPE}.py
from modeller import *
from modeller.scripts import complete_pdb
import allosmod

env = environ(rand_seed=${RAND})
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

# Read in HETATM records from template PDBs
env.io.hetatm = True 

a = allosmod.AllosModel(env, inifile  = 'random.ini', deviation=None, alnfile='align.ali', 
EOF

echo -n "csrfile  = 'converted.rsr', " >>model_${RUNTYPE}.py
echo -n "knowns=('${F[0]}'" >>model_${RUNTYPE}.py
awk '(NR>1&&NF>0){printf ",@"$1"@"}' ${LIST_KNOWNS} | sed "s/@/'/g" >>model_${RUNTYPE}.py
echo "), sequence='${TARG_SEQ}')" >>model_${RUNTYPE}.py
echo >>model_${RUNTYPE}.py

cat <<EOF >>model_${RUNTYPE}.py
# Very thorough VTFM optimization:
a.library_schedule = allosmod.MDopt
a.max_var_iterations = 500

# MD optimization:
a.md_level = allosmod.moderate_am

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

fi

fi

#/salilab/diva1/home/modeller/modSVN model_${RUNTYPE}.py
