#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

FIL_PM=$1
LS2PDB=$2 #used to list all pdb's: *.pdb
###OPT=$3 #if specified, use this in place of Am2SD for DQ

NRES=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $0}' ${FIL_PM} |\
      awk 'BEGIN{FS="";lc=""}(lc!=$22){li=0}(li!=$23$24$25$26){a+=1}{li=$23$24$25$26;lc=$22}END{print a}'`
ls -1 $LS2PDB | $SCRIPT_DIR/randomize_list_2.pl | tail -n500 >tempslist #max 500 structures in getqmatrix
if (test ! -s tempslist); then echo ERROR get_qmatrix; pwd; exit; fi
NFIL=`awk 'END{print NR}' tempslist`

echo $NRES 1 $NRES >targlist
echo 11.0 >>targlist
echo $NFIL >>targlist
cat tempslist >>targlist

$SCRIPT_DIR/getqmatrix_ca 

#AVG=`awk '{print $1}' qcut_matrix.dat | cat -b | awk '($1>0){print $2}' | awk '(NR==1){a=0;n=0}{a+=$1; n+=1}END{printf "%9.4f\n",a/n}' | awk '{print $1}'`
#SD=`awk '{print $1}' qcut_matrix.dat | cat -b | awk '($1>0){print $2}' |\
#      awk '(NR==1){n=0;a=0}{a+=($1-"'${AVG}'")^2;n+=1}END{printf "%9.4f\n",sqrt(a/n)}' | awk '{print $1}'`

###if test -z $OPT; then
###    Am2SD=`echo $AVG $SD | awk '{print $1-$2}'`
###else
###    Am2SD=$OPT
###fi

awk '{printf $1" "}(NR%'${NFIL}'==0){printf "\n"}' qcut_matrix.dat > tempqm301
paste -d" " tempslist tempqm301 >qmatrix.dat

#CQ=`awk '{for(a=1;a<=NF;a++){if(a==1){nd[NR]=0};if(a>1&&$a<.8){nd[NR]+=1}}}END{for(a=1;a<=NR;a++){print nd[a]+1}}' qmatrix.dat |\
#    awk 'BEGIN{a=0;b=0}{a+=$1;b+=1}END{if(b>0){printf "%9.4f\n",a/b}else{print "0.000"}}' | awk '{print $1}'`
#DQ=`awk '{for(a=1;a<=NF;a++){if(a==1){nd[NR]=0};if(a>1&&$a<'${Am2SD}'){nd[NR]+=1}}}END{for(a=1;a<=NR;a++){print nd[a]}}' qmatrix.dat |\
#    awk 'BEGIN{a=0;b=0}{a+=$1;b+=1}END{printf "%9.4f\n",a/b}' | awk '{print $1}'`
AQ=`awk '{for(a=1;a<=NF;a++){if(a==NF){qavg=qavg-1.0;ctr=ctr-1.0};if(a>1){qavg+=$a;ctr+=1.0}}}END{if(ctr>0){printf "%9.2f\n",qavg/ctr}else{print "0.000"}}' qmatrix.dat |\
    awk '{print $1}'`

#echo $CQ $AQ $AVG $SD $NFIL >cq_aq_qavg_qsd.dat
echo Qa,b: $AQ >cq_aq_qavg_qsd.dat

rm tempslist tempqm301 qcut_matrix.dat targlist
