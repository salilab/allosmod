#!/bin/bash
#pdb to ali, will output hetero atoms except HOH as BLK residues (".") and heme as (h)

FIL1=$1
CHAIN=$2 #optional to specify, if not then output all chains

if test -z $CHAIN; then

CHAIN=(`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' ${FIL1} | awk 'BEGIN{FS="";lc=""}(lc!=$22){print $22}{lc=$22}'`)

#if some chains empty and some filled, replace empty chains
TEST_CHAIN_NO_CHAIN=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $0}' ${FIL1} | awk 'BEGIN{FS="";a=0}($22==" "){a=1}END{print a}'`
if test `echo "${TEST_CHAIN_NO_CHAIN}==1" |bc -l` -eq 1; then
    awk 'BEGIN{FS=""}{if(($1$2$3$4=="ATOM"||$1$2$3$4$5$6=="HETATM")&&$22==" "){for (a=1;a<=21;a++){printf $a} \
    {printf "@"}for (a=23;a<=NF;a++) {{printf $a}if(a==NF){printf "\n"}}}else{print $0}}' $FIL1 >tempp2a02
    mv tempp2a02 $FIL1
fi

#get protein sequence and allowed hetero atoms
if test -z ${CHAIN[0]}; then
#    awk '($5!=i&&$1=="ATOM"){print $4}($5!=i){i=$5}' $FIL1 >temp5499
    awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $18$19$20,$23$24$25$26$27}\
   ($1$2$3$4=="HETA"&&$18$19$20!="HOH"){print $18$19$20,$23$24$25$26$27,"het"}' $FIL1 |\
    awk 'BEGIN{i=9999}($2!=i||$1!=aa){if(NF==2){print $1}else\
         {o=0;if($1=="HEM"){print "h";o=1};if($1=="PPI"){print "f";o=1};if($1=="RIB"){print "r";o=1};if(o==0){print "."}}}\
         ($2!=i||$1!=aa){aa=$1;i=$2}' >temp5499
else
    awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $18$19$20,$22,$23$24$25$26$27}\
   ($1$2$3$4=="HETA"&&$18$19$20!="HOH"){print $18$19$20,$22,$23$24$25$26$27,"het"}' $FIL1 |\
    awk 'BEGIN{i=9999}(prot==1&&$2!=c){print "/"}($3!=i||$2!=c||$1!=aa){if(NF==3){print $1}else\
         {o=0;if($1=="HEM"){print "h";o=1};if($1=="PPI"){print "f";o=1};if($1=="RIB"){print "r";o=1};if(o==0){print "."}}}\
         ($3!=i||$2!=c||$1!=aa){aa=$1;c=$2;i=$3;prot=1}' >temp5499
fi

LCHAIN=`echo ${CHAIN[@]} | awk '{print $NF}'`
INVERTED=`awk 'BEGIN{FS=""}(($1$2$3$4=="ATOM"||$1$2$3$4=="HETA")&&$22=="'${LCHAIN}'"){print $23$24$25$26$27}' $FIL1 |\
          awk 'BEGIN{li=-999;inverted=0}($1<li){inverted=1}{li=$1}END{print inverted}'`
SRES=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $23$24$25$26$27;exit}' $FIL1 | awk '{print $1}'`
LRES=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4=="HETA"){print $23$24$25$26$27,$18$19$20}' $FIL1 | awk '($2!="HOH"){a=$1}END{print a}'`
#NRES=`awk '($1!="/"&&$1!="."&&$1!="PPP"){a+=1}END{print a+'${SRES}'-1}' temp5499 | awk '{if('${LRES}'>$1){print '${LRES}'}else{print $1}}'`
NRES=`awk '($1!="/"&&$1!="PPP"){a+=1}END{print a+'${SRES}'-1}' temp5499 | awk '{if('${LRES}'>$1||'${INVERTED}'==1){print '${LRES}'}else{print $1}}'` #use if hetatoms turned on

echo ">P1;"$FIL1 
echo "structureX:"$FIL1":${SRES}    :${CHAIN[0]}:${NRES}   :${LCHAIN}:::-1.00:-1.00" 
awk '{o=0}($1=="ALA"){printf "A";o=1}($1=="ARG"){printf "R";o=1}($1=="ASN"){printf "N";o=1}($1=="ASP"){printf "D";o=1}\
($1=="CYS"){printf "C";o=1}($1=="GLU"){printf "E";o=1}($1=="GLN"){printf "Q";o=1}($1=="GLY"){printf "G";o=1}\
($1=="HIS"||$1=="HID"||$1=="HIE"||$1=="HIP"||$1=="HSD"||$1=="HSE"||$1=="HSP"){printf "H";o=1}\
($1=="ILE"){printf "I";o=1}($1=="LEU"){printf "L";o=1}($1=="LYS"){printf "K";o=1}\
($1=="MET"||$1=="MSE"){printf "M";o=1}($1=="PHE"){printf "F";o=1}($1=="PRO"){printf "P";o=1}($1=="SER"){printf "S";o=1}\
($1=="THR"){printf "T";o=1}($1=="TRP"){printf "W";o=1}($1=="TYR"){printf "Y";o=1}($1=="VAL"){printf "V";o=1}\
($1=="ADE"){printf "a";o=1}($1=="CYT"){printf "c";o=1}($1=="GUA"){printf "g";o=1}($1=="THY"){printf "s";o=1}($1=="URA"){printf "u";o=1}\
($1=="A"){printf "a";o=1}($1=="C"){printf "c";o=1}($1=="G"){printf "g";o=1}($1=="T"){printf "s";o=1}($1=="U"){printf "u";o=1}\
($1=="DA"){printf "e";o=1}($1=="DC"){printf "j";o=1}($1=="DG"){printf "l";o=1}($1=="DT"){printf "t";o=1}($1=="DU"){printf "v";o=1}\
($1=="h"){printf "h";o=1}($1=="f"){printf "f";o=1}($1=="r"){printf "r";o=1}\
($1=="/"){printf "/";o=1}($1=="."){printf ".";o=1}($1=="PPP"){printf "-";o=1}\
(o==0){printf "."}\
((NR%75)==0){printf "\n"}END{printf "*\n\n"}' temp5499 

#($1=="NAG"||$1=="NGA"||$1=="GLB"||$1=="FUC"||$1=="MAN"||$1=="BMA"||$1=="NAN"){printf "."}\
#($1=="ZN"||$1=="MG"||$1=="CA"||$1=="NA"){printf "."}\

else #output specified chains

R_C=(`echo $CHAIN | awk 'BEGIN{FS=""}{for(a=1;a<=NF;a++){print $a}}'`)
prm temp5499
ctr=0
for cc in ${R_C[@]}; do
    ctr=$((${ctr}+1))
    if test `echo "${ctr}>1" |bc -l` -eq 1; then echo "/" >>temp5499; fi
#    awk 'BEGIN{FS=""}($22=="'${cc}'"){print $0}' $FIL1 | awk '{print $4}' >>temp5499
    awk '($6!=i&&$5=="'${cc}'"){print $4;i=$6}' $FIL1 >>temp5499
done
INVERTED=`awk 'BEGIN{FS=""}(($1$2$3$4=="ATOM"||$1$2$3$4=="HETA")&&$22=="'${cc}'"){print $23$24$25$26$27}' $FIL1 |\
          awk 'BEGIN{li=-999;inverted=0}($1<li){inverted=1}{li=$1}END{print inverted}'`
#SRES=`awk '($3=="CA"&&$5=='${R_C[0]'){print $6;exit}' $FIL1`
LRES=`awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"){print $23$24$25$26$27}' $FIL1 | awk 'END{print $1}'`
#NRES=`awk '($1!="/"&&$1!="."&&$1!="PPP"){a+=1}END{print a+'${SRES}'-1}' temp5499 | awk '{if('${LRES}'>$1){print '${LRES}'}else{print $1}}'`
NRES=`awk '($1!="/"&&$1!="PPP"){a+=1}END{print a+'${SRES}'-1}' temp5499 | awk '{if('${LRES}'>$1||'${INVERTED}'==1){print '${LRES}'}else{print $1}}'` #use if hetatoms turned on
echo ">P1;"${FIL1}${CHAIN}
echo "structureX:"${FIL1}${R_C[0]}":${SRES}    :"${cc}":${NRES}   :A:::-1.00:-1.00" 
awk '{o=0}($1=="ALA"){printf "A";o=1}($1=="ARG"){printf "R";o=1}($1=="ASN"){printf "N";o=1}($1=="ASP"){printf "D";o=1}\
($1=="CYS"){printf "C";o=1}($1=="GLU"){printf "E";o=1}($1=="GLN"){printf "Q";o=1}($1=="GLY"){printf "G";o=1}\
($1=="HIS"||$1=="HID"||$1=="HIE"||$1=="HIP"||$1=="HSD"||$1=="HSP"){printf "H";o=1}\
($1=="ILE"){printf "I";o=1}($1=="LEU"){printf "L";o=1}($1=="LYS"){printf "K";o=1}\
($1=="MET"){printf "M";o=1}($1=="PHE"){printf "F";o=1}($1=="PRO"){printf "P";o=1}($1=="SER"){printf "S";o=1}\
($1=="THR"){printf "T";o=1}($1=="TRP"){printf "W";o=1}($1=="TYR"){printf "Y";o=1}($1=="VAL"){printf "V";o=1}\
($1=="ADE"){printf "a";o=1}($1=="CYT"){printf "c";o=1}($1=="GUA"){printf "g";o=1}($1=="THY"){printf "s";o=1}($1=="URA"){printf "u";o=1}\
($1=="A"){printf "a";o=1}($1=="C"){printf "c";o=1}($1=="G"){printf "g";o=1}($1=="T"){printf "s";o=1}($1=="U"){printf "u";o=1}\
($1=="DA"){printf "e";o=1}($1=="DC"){printf "j";o=1}($1=="DG"){printf "l";o=1}($1=="DT"){printf "t";o=1}($1=="DU"){printf "v";o=1}\
($1=="h"){printf "h";o=1}($1=="f"){printf "f";o=1}($1=="r"){printf "r";o=1}\
($1=="/"){printf "/";o=1}($1=="."){printf ".";o=1}\
(o==0){printf "."}\
((NR%75)==0){printf "\n"}END{printf "*\n\n"}' temp5499 
fi

rm temp5499
