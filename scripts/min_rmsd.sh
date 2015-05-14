#!/bin/bash
# 1) FILE1 2) CHAIN1 3) FILE2 4) CHAIN2
# calculates rmsd between 2 structures for this in ATOM

FF1=$1
FF2=$2

bnFF1=`basename $FF1`
bnFF2=`basename $FF2`

echo $FF1 >prolist.in
echo $FF2 >>prolist.in

#MWRITE is to output fitted structures
cat <<SUB > profit.in
multi prolist.in
ATOMS CA
#ATOMS CA,N,C,O
#ATOMS ^N,CA,C,O
#ATOMS *
ALIGN
fit
#MWRITE
quit
SUB

/netapp/sali/allosmod/profit < profit.in >profit.out

RR=`grep RMS profit.out  |awk 'END{print $2}'`

echo $bnFF1 $bnFF2 $RR

rm profit.in prolist.in profit.out
