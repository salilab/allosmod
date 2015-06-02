#!/bin/bash

# Absolute path containing this and other scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

FIL_PM=$1
LS2PDB=$2 #used to list all pdb's: ls input/pred_dE*/*_[0-9]

if (test ! -e ${FIL_PM}); then echo PM file missing, filter_lowq.sh; exit; fi

R_RES=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $18$19$20}' ${FIL_PM} | sort -u`)
isNUCLEO=0
isPROT=0
for res in ${R_RES[@]}; do
    if test $res == "ADE"; then isNUCLEO=1; fi
    if test $res == "A"; then isNUCLEO=1; fi
    if test $res == "DA"; then isNUCLEO=1; fi
    if test $res == "THY"; then isNUCLEO=1; fi
    if test $res == "T"; then isNUCLEO=1; fi
    if test $res == "DT"; then isNUCLEO=1; fi
    if test $res == "URA"; then isNUCLEO=1; fi
    if test $res == "U"; then isNUCLEO=1; fi
    if test $res == "DU"; then isNUCLEO=1; fi
    if test $res == "GUA"; then isNUCLEO=1; fi
    if test $res == "G"; then isNUCLEO=1; fi
    if test $res == "DG"; then isNUCLEO=1; fi
    if test $res == "CYT"; then isNUCLEO=1; fi
    if test $res == "C"; then isNUCLEO=1; fi
    if test $res == "DC"; then isNUCLEO=1; fi
    if test $res == "ALA"; then isPROT=1; fi
    if test $res == "LEU"; then isPROT=1; fi
    if test $res == "GLY"; then isPROT=1; fi
    if test $res == "SER"; then isPROT=1; fi
    if test $res == "ALA"; then isPROT=1; fi
done

if test `echo "${isPROT}==1" |bc -l` -eq 1; then
    QCUT=0.25
else #nucleic acid is used to calculate Q, but if not restrained by protein then Q of nuc acid can vary a lot
    exit
fi

NRES=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $0}' ${FIL_PM} |\
      awk 'BEGIN{FS="";lc=""}(lc!=$22){li=0}(li!=$23$24$25$26){a+=1}{li=$23$24$25$26;lc=$22}END{print a}'`

ls -1 $LS2PDB >tempflq

allosmod get_q_ca $FIL_PM 11.0 `cat tempflq`

paste tempflq qscore1to${NRES}.dat | awk '($3<'${QCUT}'){print "Q = "$3", rm "$1}' >>run.log
paste tempflq qscore1to${NRES}.dat | awk '($3<'${QCUT}'){print "rm "$1}' | sh

paste tempflq qscore1to${NRES}.dat | awk '($3>='${QCUT}'){print $1}' >filenames

paste tempflq qscore1to${NRES}.dat >qscore.dat
rm tempflq qs_cut1to${NRES}.dat qscore1to${NRES}.dat
