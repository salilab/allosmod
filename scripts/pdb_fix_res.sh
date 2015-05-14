#!/bin/bash
#fix: 1) MSE->MET, 2) H[IS][DEP]->HIS

FIL=$1


awk 'BEGIN{FS=""}($1$2$3$4=="ATOM"||$1$2$3$4$5$6=="HETATM"){print $0}' $FIL |\
awk 'BEGIN{FS=""}{if($13$14!="SE"){atom=$13$14$15}else{atom=" SD"}}\
     {if($18$19$20=="MSE"){printf "ATOM  "; \
     for(a=7;a<=12;a++){printf $a}{printf atom$16$17"MET"} for(a=21;a<=NF;a++){{printf $a}if(a==NF){printf "\n"}}}
     else{print $0}}' |\
awk 'BEGIN{FS=""}{atom=$13$14$15}\
     {if($18$19$20=="HID"||$18$19$20=="HIE"||$18$19$20=="HIP"||$18$19$20=="HSD"||$18$19$20=="HSE"||$18$19$20=="HSP"){printf "ATOM  "; \
     for(a=7;a<=12;a++){printf $a}{printf atom$16$17"HIS"} for(a=21;a<=NF;a++){{printf $a}if(a==NF){printf "\n"}}}
     else{print $0}}' 
