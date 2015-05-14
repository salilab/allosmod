#!/bin/bash

FIL=$1

/netapp/sali/allosmod/dssp $FIL | awk 'BEGIN{start=0}(start==1){print $0}($2=="RESIDUE"&&$3=="AA"){start=1}' |\
awk '(NR==1||$2==lresid+1||($2>-9999&&$2<9999&&$3!=lchain)){print $0;lresid=$2;lchain=$3}' |\
awk 'BEGIN{FS=""}{printf "%s\n",$17}' | awk '{if(NF>0){print $0}else{print "-"}}' >dssp.out



#awk '(NR==1||$2==lresid+1||($2<9999&&$3!=lchain)){print $0}{lresid=$2;lchain=$3}' |\
