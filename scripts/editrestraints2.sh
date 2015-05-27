#!/bin/bash
# 1-2) restraint_file 3-4) pdb_file 2 define res-res contacts 5) atomlistASRS 6) sigmas 7) rcut 8) #templates 9) delEmax
#IMPORTANT: inputs PDB's must have numbering from 1 to N (including HETATM's) with no gaps or repeats, vital for communication between getcont.f and editrestraints.f

RESTR_FIL1=$1 #first restrt file is for templates used for RS-RS contacts only (usually 2 templates)
RESTR_FIL2=$2 #second restrt file is for template used for AS-AS contacts and AS-RS interface contacts (usually 1 template)
PDB1=$3 #PDB1 used in editrestraints.f to extract atom characteristics (AS v RS,SC v BB)
LIST_PDB=$4 #list of pdb files to define contact maps
atomlistASRS=$5 #label atoms as AS or RS
# sigma for distance restraints for AS,RS,or interface contacts
sig_AS=`echo $6 | awk 'BEGIN{FS=","}{print $1}'`
sig_RS=`echo $6 | awk 'BEGIN{FS=","}{print $2}'`
sig_inter=`echo $6 | awk 'BEGIN{FS=","}{print $3}'`
# distance cutoff for distance restraints
rcut=$7  #15.0
# total number of basins in landscape, used for scaling sigma
ntotal=$8 
# parameters for the truncated Gaussian
delEmax=$9
slope=4.0
scl_delx=0.7
#parameters for break.dat
nbreak=${10}
rcoarse=${11}
#increase local rigidity
locrigid=${12}
#increase local rigidity for H-bonds between beta structures
#locbeta=${13} active for proteins < 5% alpha, >20% beta

NATOM1=`awk 'END{print NR}' $PDB1`
NATOM2=`awk 'END{print NR}' $atomlistASRS`
if test $NATOM1 != $NATOM2; then echo ERROR pm file not same length as atomlistASRS; exit; fi

#get contacts
if test -e tempbindmat; then rm tempbindmat; fi
for pdb in `cat ${LIST_PDB} | awk '{print "pm_"$1}'`; do
    allosmod get_contacts $pdb $rcut | awk '{print $1,$2,$3,$4}' >>tempbindmat
    echo "contact def exec: getcont_sc_gt2: "$pdb
done
sort -u tempbindmat >temp55
mv temp55 tempbindmat

#merge restraint files
echo $RESTR_FIL1 >targlist
echo `awk 'BEGIN{a=0}($1=="R"){a+=1}END{print a}' $RESTR_FIL1` >>targlist
echo $RESTR_FIL2 >>targlist
echo `awk 'BEGIN{a=0}($1=="R"){a+=1}END{print a}' $RESTR_FIL2` >>targlist
echo tempbindmat >>targlist
awk 'END{print NR}' tempbindmat >>targlist
echo $PDB1 >>targlist
awk 'END{print NR}' $PDB1 >>targlist
echo $atomlistASRS >>targlist
awk 'END{print NR}' $atomlistASRS >>targlist
echo $sig_AS $sig_RS $sig_inter >>targlist
echo $rcut >>targlist
echo $ntotal >>targlist
echo $delEmax $slope $scl_delx >>targlist
echo $nbreak break.dat >>targlist
if test $rcoarse == "true"; then
    echo 1 >>targlist
else
    echo 0 >>targlist
fi
if test $locrigid == "true"; then
    echo 1 >>targlist
else
    echo 0 >>targlist
fi
#test for beta structure
/netapp/sali/allosmod/get_ss.sh $PDB1
PBETA=`awk '($1=="E"){a+=1}END{if(NR>0){print a/NR}else{print 0}}' dssp.out`
PHELX=`awk '($1=="H"){a+=1}END{if(NR>0){print a/NR}else{print 0}}' dssp.out`
SSTEST=`echo $PBETA $PHELX | awk '{if($1>.20&&$2<.05){print "true"}else{print "false"}}'`
if test $SSTEST == "true"; then
    NDSSP=`awk 'END{print NR}' dssp.out`
    echo $NDSSP dssp.out >>targlist
else
    echo 0 dssp.out >>targlist
fi

/netapp/sali/allosmod/editrestraints >edited.rsr

cp tempbindmat contacts.dat
echo
echo "edit restraints sig_AS sig_RS sig_inter rcut:"
echo $sig_AS $sig_RS $sig_inter $rcut 
echo "edit restraints targlist: "
awk '{print "  # "$0}' targlist
echo

rm targlist tempbindmat dssp.out
