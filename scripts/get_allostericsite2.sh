#!/bin/bash
# outputs contact list and PDB file for residues in PDB2 within rcut of LIG1 (after superposition of PDB2 onto PDB1)...
# and PDB file for residues in PDB2 corresponding to those in PDB1 NOT within rcut of LIG1... these files are used to create atomlistASRS, which is an input for PM
# and reslistASRS for residues in PDB2
# 1) PDB1 file of the bound state 
# 2) corresponding ligand to PDB1 (if nonprotein, change atom_type NOT CA and res_type LYS)
# 3) model of PDB2 file (used to determine allosteric site).. to be superimposed onto PDB1 
# 4) rcut to define allosteric site using PDB2

PDB1=$1
############
LIG1=$2
#setatomX $LIG1 >lig_nonprotein
#LIG1=lig_nonprotein
############
PDB2=$3 #should be pm file with renumbered residues and chain
PMLEN=`awk 'BEGIN{FS="";a=0}($1$2$3$4=="ATOM"){a+=1}END{print a}' $PDB2`
PMHET=`awk 'BEGIN{FS="";a=0}($1$2$3$4=="HETA"){a+=1}END{print a}' $PDB2`
rcut=$4

# Get the 'allosmod' binary in the path
module load allosmod

mkdir allostericsite_${rcut}
cd allostericsite_${rcut}
cp ../$PDB1 ../$LIG1 ../$PDB2 ./

if test `echo "${rcut}>0" |bc -l` -eq 1; then

#align PDB2 to PDB1 and superimpose antigen
allosmod salign0 $PDB1 $PDB2
PMFIT=`echo ${PDB2} | awk 'BEGIN{FS=""}{if($(NF-3)$(NF-2)$(NF-1)$NF==".pdb"){for(a=1;a<=NF-4;a++){printf $a}}else{printf $0}}END{print "_fit.pdb"}'`

#determine residues in PDB2 that contact LIG1
echo ${PMFIT} >targlist
awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $0}' ${PMFIT} |\
      awk 'BEGIN{FS="";lc=""}(lc!=$22){li=0}(li!=$23$24$25$26){a+=1}{li=$23$24$25$26;lc=$22}END{print a}' >>targlist
echo $LIG1 >>targlist
awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $22$23$24$25$26}' $LIG1 | sed "s/ //g" | sort -u | awk 'END{print NR}' >>targlist
#awk '($1=="ATOM"||$1=="HETATM"){print $5$6}' $LIG1 | sort -u | awk 'END{print NR}' >>targlist
echo $rcut >>targlist
/netapp/sali/allosmod/getcont_inter_sc >tempbindmat
cat tempbindmat | awk '{print $2$1}' |sort -u | awk 'BEGIN{FS=""}{print $1,$2$3$4$5}' |sort -nk2 | awk '{print $1$2}' >temp321

#print out residues to pdb for allosteric site
if test -e allostericsite.pdb; then rm allostericsite.pdb; fi
if test -e tempdps10; then rm tempdps10; fi
for s in `cat temp321`; do
    TCHAIN=`echo $s | awk 'BEGIN{FS=""}{print $1}'`
    RES=`echo $s | awk 'BEGIN{FS=""}{for(a=2;a<=NF;a++){printf $a}}' | awk '{print $1}'`
    awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $22" "$23$24$25$26" "$0}' ${PMFIT} |\
         awk '($1=="'$TCHAIN'"&&$2=="'$RES'"){print $0}' | awk 'BEGIN{FS=""}{for(a=8;a<=NF;a++){printf $a;if(a==NF){printf "\n"}}}' >>allostericsite.pdb
    awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $22" "$23$24$25$26" "$0}' $PDB2 |\
         awk '($1=="'$TCHAIN'"&&$2=="'$RES'"){print NR,"AS"}' >>tempdps10 #to make allostericsite same numbering as pm
done

#print atomlistASRS
if test -s tempdps10; then
    sort -nk1 tempdps10 >tempdps11
    /netapp/sali/allosmod/get_fillindex.sh tempdps11 AS RS $PMLEN >atomlistASRS
    if test `echo "${PMHET}>0" |bc -l` -eq 1; then
	echo 1 | awk '{for(a=('${PMLEN}'+1);a<=('${PMLEN}'+'${PMHET}');a++){print a" AS"}}' >>atomlistASRS
    fi
else
    echo ${PMLEN} ${PMHET} | awk '{for(a=1;a<=($1+$2);a++){print a" RS"}}' >atomlistASRS
fi

#make subregion.in for qsubregion calcs
if test -s allostericsite.pdb; then
    NRES=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $0}' ${PMFIT} |\
      awk 'BEGIN{FS="";lc=""}(lc!=$22){li=0}(li!=$23$24$25$26){a+=1}{li=$23$24$25$26;lc=$22}END{print a}'`
    awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $23$24$25$26}' allostericsite.pdb | sort -nu >tempas661
    /netapp/sali/allosmod/get_fillindex.sh tempas661 1 2 $NRES |\
         awk 'BEGIN{print "2";ctr=0}{printf "%3.0f",$2;ctr+=1}(ctr==10){printf "\n";ctr=0}END{printf "\n"}' >subregion.in
else
    echo "" >allostericsite.pdb
fi

else #rcut is 0
echo ${PMLEN} ${PMHET} | awk '{for(a=1;a<=($1+$2);a++){print a" RS"}}' >atomlistASRS
echo "" >allostericsite.pdb
fi

rm tempdps1[01] temp321 tempbindmat tempas661
