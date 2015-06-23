#!/bin/bash
#preprocess pdb files then find si between pdbs in list

INPFIL=$1 #file containing sequence used experiment (one letter code)
DIR=$2 #path to INPFIL and list

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Get the 'allosmod' binary in the path
. /etc/profile
module load allosmod

cd $DIR

NRES=`awk 'BEGIN{FS=""}{for(a=1;a<=NF;a++){print $a}}' $INPFIL | awk 'BEGIN{a=0}($1!="/"){a+=1}END{print a}'`
ichain=`awk 'BEGIN{FS=""}{for(a=1;a<=NF;a++){print $a}}' $INPFIL | awk 'BEGIN{a=0}($1=="/"){a+=1}END{print a}'`
R_CHAIN=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

#make input alignment file
echo ">P1;pm.pdb" >tempms004.ali
echo "structureX:pm.pdb:1    :A:${NRES}   :${R_CHAIN[${ichain}]}:::-1.00:-1.00" >>tempms004.ali
awk 'BEGIN{FS="";ctr=0}{for(a=1;a<=NF;a++){printf $a;ctr+=1;if(ctr%75==0){printf "\n"}}}END{printf "*\n\n"}' $INPFIL >>tempms004.ali

maxNREStemp=0
for fil in `cat list`; do
    NMRtest=`awk '($1=="REMARK"&&$2=="210"&&$3=="EXPERIMENT"){print $6}' $fil | awk '{a=$1}END{if(a!=null){print $1}else{print "0"}}'`
    #take only first model if determined by NMR
    if test $NMRtest != "NMR"; then
	awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' $fil >tempgms4955; mv tempgms4955 $fil
    else
	awk 'BEGIN{FS=""}($1$2$3$4$5$6=="ENDMDL"){exit}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' $fil >tempgms4955; mv tempgms4955 $fil
    fi
    maxNREStemp=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' ${fil} |\
                 awk 'BEGIN{FS="";lc="";li=-999}(lc!=$22){li=-999}(li!=$23$24$25$26$27){a+=1}{li=$23$24$25$26$27;lc=$22}END{print a}' |\
                 awk '{if($1>'${maxNREStemp}'){print $1}else{print '${maxNREStemp}'}}'`

    #if no chainid, set to @
    TEST_CHAIN_NO_CHAIN=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' ${fil} | awk 'BEGIN{FS="";a=0}($22==" "){a=1}END{print a}'`
    if test `echo "${TEST_CHAIN_NO_CHAIN}==1" |bc -l` -eq 1; then
	awk 'BEGIN{FS=""}{if(($1$2$3$4=="ATOM"||$1$2$3$4$5$6=="HETATM")&&$22==" "){for (a=1;a<=21;a++){printf $a} \
             {printf "@"}for (a=23;a<=NF;a++) {{printf $a}if(a==NF){printf "\n"}}}else{print $0}}' $fil >tempp2a02
	mv tempp2a02 $fil
    fi

    #test for redundant chains, if so rename chains
    REDUNTtest=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $22$23$24$25$26}' $fil | sed "s/ //g" |\
                awk 'BEGIN{ll=-1}($1!=ll){a+=1}{ll=$1}END{print a}'`
    REDUNTtestb=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $22$23$24$25$26}' $fil | sed "s/ //g" | sort -u | awk 'END{print NR}'`

    if test `echo "${REDUNTtest}!=${REDUNTtestb}" |bc -l` -eq 1; then
	R_IND=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $22,$23$24$25$26}' ${fil} |\
                awk '(NR==1){lc=$1;li=$2}($1!=lc||($1==lc&&li>$2)){print NR}{lc=$1;li=$2}'` 999999999)
	li=0; ctr=0; if test -e tempgms_1.pdb; then rm tempgms_*.pdb; fi
	for i in ${R_IND[@]}; do
	    ctr=$((${ctr} + 1))
	    awk '(NR>='${li}'&&NR<'${i}'){print $0}' $fil >tempgms_${ctr}.pdb
	    R_FF[$((${ctr}-1))]=tempgms_${ctr}.pdb
	    li=$i
	done
	ctr=-1
	rm $fil
	
	for i in ${R_FF[@]}; do
	    ctr=$((${ctr} + 1))
	    allosmod setchain $i ${R_CHAIN[${ctr}]} >>$fil
	done
	rm tempgms_*.pdb
    fi

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
echo "aln.write(file='align.ali')" >>modeller.in

/salilab/diva1/home/modeller/modSVN modeller.in 2> /dev/null
#/salilab/diva1/home/modeller/modpy.sh modeller.in

if test -s align.ali; then
    echo ""
else
    tail -n20 modeller.in.log >align.ali
fi

#check for improper NRES, ie less than 10 % of the template length
testIMPROPER=`echo $NRES $maxNREStemp | awk '{if(($1/$2)<0.1){print 1}else{print 0}}'`
if test `echo "${testIMPROPER}==1" |bc -l` -eq 1; then
    echo "Dynamically allocated memory, pass error to frontend" >align.ali
fi

rm tempms004.ali modeller.in modeller.in.log inpseq
