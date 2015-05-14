#!/bin/bash

LIST=$1 #list with path to all structures to be analzed
if test -z $LIST; then echo must specify list; exit; fi

mkdir temp_gss33

npdb=0
for s in `cat $LIST`; do
    npdb=$((${npdb} + 1))
    cp $s temp_gss33/${npdb}.pdb
done

cd temp_gss33

cat <<EOF >score_soap.py
from modeller import *
from modeller import soap_protein_od
from modeller.scripts import complete_pdb

env = environ()
log.verbose()
env.io.atom_files_directory = ['../atom_files']
env.libs.topology.read(file='\$(LIB)/top_heav.lib')
env.libs.parameters.read(file='\$(LIB)/par.lib')

env.edat.dynamic_sphere = False
env.edat.contact_shell = 8.
sl = soap_protein_od.Scorer()
#sl = soap_protein_od.Scorer(library='/netapp/sali/pweinkam/bin/db/soap_protein_od.hdf5')
env.edat.energy_terms.append(sl)

ctr=1
for i in range(${npdb}):
     mdl = complete_pdb(env, '%s.pdb' % ctr)
     s = selection(mdl)
     outff=str(ctr) + '.profile'
     s.get_energy_profile(physical.xy_distance).get_normalized().write_to_file(outff)
     ctr=ctr+1

#         mdl = complete_pdb(env, 'cm.pdb.B999900%s.pdb' % ctr)
#         s = selection(mdl)
#         outff='00' + str(ctr) + '.profile'
#         s.get_energy_profile(physical.xy_distance).get_normalized().write_to_file(outff)
#         print s.energy(file='energy_soapod.dat')[0]
#         ctr=ctr+1
EOF

/salilab/diva1/home/modeller/modSVN score_soap.py 

cd ..

npdb=0
if test -e energy_soap.dat; then rm energy_soap.dat; fi
for s in `cat $LIST`; do
    npdb=$((${npdb} + 1))
    bndir=`dirname $s`
    awk 'BEGIN{a=0}{a+=$2}END{print "'${s}' "a}' temp_gss33/${npdb}.profile >>energy_soap.dat
#    mv temp_gss33/${npdb}.profile ${s}.profile
done

rm -rf temp_gss33
