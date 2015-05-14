#!/bin/bash
#outputs index (with $ival) and #'s in between index (with $mval) up to $tot
#if IVAL set to @, then col 2 from FIL is used instead
#assumes index starts at 1

FIL=$1
IVAL=$2 #optional set to @
MVAL=$3
TOT=$4

if test $IVAL != "@"; then
    awk '{print $1,"'${IVAL}'"}' $FIL |\
    awk 'BEGIN{last=0}(NR==1&&$1>1){for(a=1;a<$1;a++){print a,"'${MVAL}'"}{last=$1}}\
    {if($1!=last+1){for(a=last+1;a<$1;a++){print a,"'${MVAL}'"}{print $1,"'${IVAL}'";last=$1}}else{print $1,"'${IVAL}'";last=$1}}\
    END{if(last<'${TOT}'){for(a=last+1;a<='${TOT}';a++){print a,"'${MVAL}'"}}}' 
else
    awk '{print $0}' $FIL |\
    awk 'BEGIN{last=0}(NR==1&&$1>1){for(a=1;a<$1;a++){print a,"'${MVAL}'"}{last=$1}}\
    {if($1!=last+1){for(a=last+1;a<$1;a++){print a,"'${MVAL}'"}{print $0;last=$1}}else{print $0;last=$1}}\
    END{if(last<'${TOT}'){for(a=last+1;a<='${TOT}';a++){print a,"'${MVAL}'"}}}' 
fi
    