#!/bin/bash
#LIST format: pdb,chain,sres,eres
#top is target seq, followed by templates

#inputs initial structure and restraint files, then runs CG/MD

TARG_SEQ=$1
LIST_KNOWNS=$2
RAND=$3 #random seed
DEVIATION=$4
OPT=$5
MDTEMP=$6

# get pdb file names/chains
F=(`cat ${LIST_KNOWNS}`)
RUNTYPE="run"

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
a.md_level = allosmod.ConstTemp(md_temp=${MDTEMP})

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
a.md_level = allosmod.ConstTemp(md_temp=${MDTEMP})

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
a.md_level = allosmod.ModerateAM(md_temp=${MDTEMP})

# Repeat the whole cycle 1 time and do not stop unless obj.func. > 1E9
a.repeat_optimization = 1
a.max_molpdf = 1e9

a.starting_model = 1
a.ending_model = 1
a.make()
EOF

fi
