#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Get the 'allosmod' binary in the path
module load allosmod

F_RSR=$1 #restraint file
PM=$2 #PM file pertaining to sequence in restraint file
ZCUTOFF=$3
SCLBREAK=$4
OPT=$5 #cdensity - buried, high charge density, charged residues will be outputted; otherwise buried, charged residues will be outputted

ATOM2RES=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $23$24$25$26$27}' ${PM} | awk '{print $1}'`)
ATOMISC=( `awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $18$19$20}' ${PM} |\
    awk '{if($1=="ARG"||$1=="HIS"||$1=="LYS"||$1=="HSD"||$1=="HSE"||$1=="HSP"||$1=="HID"||$1=="HIE"||$1=="HIP"||$1=="ASP"||$1=="GLU"){print 1}else{print 0}}'`)
ATOMISA=( `awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $14$15}' ${PM} | awk '{if($1=="CA"){print 1}else{print 0}}'`)
RESISC=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' ${PM} |\
         awk 'BEGIN{FS="";lc="";li=-999}(lc!=$22){li=-999}(li!=$23$24$25$26$27){print $18$19$20}{li=$23$24$25$26$27;lc=$22}' |\
         awk '{if($1=="ARG"||$1=="HIS"||$1=="LYS"||$1=="HSD"||$1=="HSE"||$1=="HSP"||$1=="HID"||$1=="HIE"||$1=="HIP"||$1=="ASP"||$1=="GLU"){print 1}else{print 0}}'` )
NATOM=${#ATOM2RES[@]}
echo ${ATOM2RES[@]} >tempccp0841a
echo ${ATOMISC[@]}  >tempccp0841b
echo ${ATOMISA[@]}  >tempccp0841c
echo ${RESISC[@]}  >tempccp0841d

#get CA-CA pairs in restraint list
cat tempccp0841a tempccp0841b tempccp0841c $F_RSR |\
     awk '(NR==1){for(a=1;a<='${NATOM}';a++){a2r[a]=$a}}\
          (NR==2){for(a=1;a<='${NATOM}';a++){aisc[a]=$a}}\
          (NR==3){for(a=1;a<='${NATOM}';a++){aisa[a]=$a}}\
          (NR>3&&$6==2&&$5!=1&&(aisc[$9]==1&&aisc[$10]==1&&aisa[$9]==1&&aisa[$10]==1)){print a2r[$9]"\n"a2r[$10]}' | sort -n >tempccp0842

#get atom-atom pairs in restraint list
cat tempccp0841a $F_RSR | awk '(NR==1){for(a=1;a<='${NATOM}';a++){a2r[a]=$a}}\
                               (NR>1&&$6==2&&$5!=1){print a2r[$9]"\n"a2r[$10]}' | sort -n >tempccp0842tot

allosmod bin_data tempccp0842 0 0 ${ATOM2RES[$((${NATOM}-1))]} ${ATOM2RES[$((${NATOM}-1))]} | awk '{print $1+0.5,$3}' > tempccp0843
allosmod bin_data tempccp0842tot 0 0 ${ATOM2RES[$((${NATOM}-1))]} ${ATOM2RES[$((${NATOM}-1))]} | awk '{print $1+0.5,$3}' > tempccp0843tot

$SCRIPT_DIR/get_fillindex.sh tempccp0843 @ 0 ${ATOM2RES[$((${NATOM}-1))]} >charge_contpres.dat
$SCRIPT_DIR/get_fillindex.sh tempccp0843tot @ 0 ${ATOM2RES[$((${NATOM}-1))]} >tot_contpres.dat

#print num charge contacts per res if buried
paste charge_contpres.dat tot_contpres.dat | awk '{if($4>143){print $1,$2}else{print $1" 0"}}' >contpres.dat

if test $OPT == "cdensity"; then
    #getzscore of num charge contacts per res
    XAVG=`awk '{print $2}' contpres.dat | cat -b | awk '($1>0){print $2}' | awk '(NR==1){a=0;n=0}{a+=$1; n+=1}END{print a/n}'`
    XSD=`awk '{print $2}' contpres.dat | cat -b | awk '($1>0){print $2}' | awk '(NR==1){n=0;a=0}{a+=($1-"'${XAVG}'")^2;n+=1}END{print sqrt(a/n)}'`
    if test `echo "${XSD}>0" |bc -l` -eq 1; then
	awk '{print $2}' contpres.dat | cat -b | awk '($1>0){print $2}' | awk '{a=($1-'${XAVG}')/'${XSD}'}{print NR,sqrt(a*a),a}' |\
	    awk '($2>'${ZCUTOFF}'){print $1" '${SCLBREAK}'"}' >>break.dat
    else
	awk '{print $2}' contpres.dat | cat -b | awk '($1>0){print $2}' | awk '{print NR" 0 0"}' | awk '($2>'${ZCUTOFF}'){print $1" '${SCLBREAK}'"}' >>break.dat
    fi
else
    #get all buried charged residues
    cat tempccp0841d tot_contpres.dat |\
	awk '(NR==1){for(a=1;a<=NF;a++){risc[a]=$a}}\
             {if($2>143&&risc[$1]==1){print $1" '${SCLBREAK}'"}}' >>break.dat
fi

rm tempccp084[123] tempccp0841[abcd] tempccp084[23]tot charge_contpres.dat tot_contpres.dat 



