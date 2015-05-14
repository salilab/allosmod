#!/bin/bash
# print restraint between atom pairs

FIL=$1 #input.dat
PM=$2 #pm.pdb file
RESTR_TYPE=$3

R_IND1=(`grep -i $RESTR_TYPE $FIL | awk '{print $4}' | awk 'BEGIN{FS=","}{for(a=1;a<=NF;a++){print $a}}' | awk '(NR%2==1&&NF>0){print $1}'`)
R_IND2=(`grep -i $RESTR_TYPE $FIL | awk '{print $4}' | awk 'BEGIN{FS=","}{for(a=1;a<=NF;a++){print $a}}' | awk '(NR%2==0&&NF>0){print $1}'`)
R_DIST=( `grep -i $RESTR_TYPE $FIL | awk '{print $2","$4}' | awk 'BEGIN{FS=","}{for(a=2;a<=NF;a++){print $1}}' | awk '(NR%2==0){print $1}'`)
R_STDEV=(`grep -i $RESTR_TYPE $FIL | awk '{print $3","$4}' | awk 'BEGIN{FS=","}{for(a=2;a<=NF;a++){print $1}}' | awk '(NR%2==0){print $1}'`)

PM_AIND=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $23$24$25$26$27}' $PM`)
PM_ATYP=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $13$14$15$16}' $PM`)
if test `echo "${#PM_AIND[@]}!=${#PM_ATYP[@]}" |bc -l` -eq 1; then exit; fi

ctr=-1
for i in ${R_IND1[@]}; do
    ctr=$((${ctr} + 1))
    j=${R_IND2[${ctr}]}
    DIST=`echo ${R_DIST[${ctr}]} | awk '{printf "%8.4f\n",$1}'`
    STDEV=`echo ${R_STDEV[${ctr}]} | awk '{printf "%8.4f\n",$1}'`

    R_ATYP_LIB=( CA N P C O X )
    for aa in ${R_ATYP_LIB[@]}; do
	iatom=0
	for ii in ${PM_AIND[@]}; do
	    atype=${PM_ATYP[${iatom}]}
	    iatom=$((${iatom} + 1))
	    if test `echo "${ii}==${i}" |bc -l` -eq 1; then 
		if test $atype == "${aa}"; then break; fi
		if test "X" == "${aa}"; then break; fi
	    fi
	done
	if test `echo "${iatom}!=${#PM_ATYP[@]}" |bc -l` -eq 1; then break; fi
    done
    for aa in ${R_ATYP_LIB[@]}; do
	jatom=0
	for jj in ${PM_AIND[@]}; do
	    atype=${PM_ATYP[${jatom}]}
	    jatom=$((${jatom} + 1))
	    if test `echo "${jj}==${j}" |bc -l` -eq 1; then 
		if test $atype == "${aa}"; then break; fi
		if test "X" == "${aa}"; then break; fi
	    fi
	done
	if test `echo "${jatom}!=${#PM_ATYP[@]}" |bc -l` -eq 1; then break; fi
    done

    iout=`echo $iatom | awk '{printf "%5.0f\n",$1}'`
    jout=`echo $jatom | awk '{printf "%5.0f\n",$1}'`
    if test $RESTR_TYPE == "HARM"; then
	echo "R    3   1   1  27   2   2   1 ${iout} ${jout}     ${DIST}  ${STDEV}"
    elif test $RESTR_TYPE == "UPBD"; then
	echo "R    2   1   1  27   2   2   1 ${iout} ${jout}     ${DIST}  ${STDEV}"
    elif test $RESTR_TYPE == "LOBD"; then
	echo "R    1   1   1  27   2   2   1 ${iout} ${jout}     ${DIST}  ${STDEV}"
    fi
done
