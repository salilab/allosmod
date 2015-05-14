#!/bin/bash
#run foxs_ensemble AND
#prints output of best 500 clusters into log file, and pdbs for best 10 clusters into directories

DD=$1 #name of job
ESIZE=4
delZCUTOFF=1.0 #cut off for chi, below which defines "analyzed ensemble", is defined using delZCUTOFF + minimum(Zscore)

BACKADJ=`awk '($1=="backadj"){print $2}' foxs.in | sed "s/on/1/g" | sed "s/off/0/g"`

#run FoXS ensemble
/netapp/sali/dina/foxs/bin/foxs_ensemble saxs.dat filenames.txt -s ${ESIZE} -k 10000 -b ${BACKADJ} &> foxs_ensemble.out

#print cluster assignments
#awk '($1=="Cluster_Number"){clust=$3}($2=="score"&&NF==3){print $1,clust}' foxs_ensemble.out |sort -nk1 | awk '{print $2}' >cluster.dat

R_BASE_RDIR=(`awk 'BEGIN{FS="/"}{print $(NF-1)}' list_${DD} | grep _0 | awk 'BEGIN{FS=""}{for(a=1;a<=NF-1;a++){printf $a;if(a==NF-1){printf "\n"}}}' | \
              awk '{print $0}' | sort -u`)
awk 'BEGIN{FS="/"}{print "cp "$0" "$4"_XXX"$(NF-1)"_"$NF}' list_${DD} | sed "s/XXX${R_BASE_RDIR[0]}//g" | sed "s/XXX${R_BASE_RDIR[1]}//g" \
     | sed "s/XXX${R_BASE_RDIR[2]}//g" | sed "s/XXX${R_BASE_RDIR[3]}//g" >tempgs101

for ENS_SIZE in `echo $ESIZE | awk '{for(a=1;a<=$1;a++){print a}}'`; do

    #parse output: 1) Ensemble_score z-score c1 c2 & 2) pdb weight prob_occurs_in_selected_clusters avg_weight sd_weight
  if test -e ensembles_size_${ENS_SIZE}.txt; then
    awk 'BEGIN{inc=0;numc=0;nume=1;inc=0}\
     ($2=="Ensemble_score"){inc=1;numc+=1;print numc,$4,$6,$12,$15}\
     ($1=="Ensemble_score"){inc=1;numc+=1;print numc,$3,$5,$11,$14}\
     (NF==8){print numc,$2,$3,$5,$6,$7}(NF==2){print numc,$2}' ensembles_size_${ENS_SIZE}.txt \
     | sed "s/(//g" | sed "s/)//g" | sed "s/,//g" >foxs_ens${ENS_SIZE}.log


    ZCUTOFF=`awk 'BEGIN{a=-2.0}(NR==1){a=$3}END{print a+'${delZCUTOFF}'}' foxs_ens${ENS_SIZE}.log`

    #gather structures
    for iclust in `echo 10 | awk '{for(a=1;a<=$1;a++){print a}}'`; do
	R_STRUCT=(`awk '($1=='${iclust}'&&NF==5){if($3<'${ZCUTOFF}'){LOWCHI=1}else{LOWCHI=0}}\
                        ($1=='${iclust}'&&(NF==6||NF==2)&&LOWCHI==1){print $2}' foxs_ens${ENS_SIZE}.log |\
                   awk 'BEGIN{FS=""}{for(a=1;a<=NF-4;a++){printf $a;if(a==NF-4){printf "\n"}}}'`)
#echo ${ENS_SIZE} $iclust ${R_STRUCT[@]}
	if test -e ${ENS_SIZE}_${iclust}; then rm -rf ${ENS_SIZE}_${iclust}; fi
	mkdir ${ENS_SIZE}_${iclust}

	for STRUCT in ${R_STRUCT[@]}; do
	    if test -e ${STRUCT}; then
		cp ${STRUCT} ./${ENS_SIZE}_${iclust}
	    else
		grep $STRUCT tempgs101 | awk '{print $1,$2" '${ENS_SIZE}'_'${iclust}'/"$3}' |sh
	    fi
	done

	testfile=`ls -1 ${ENS_SIZE}_${iclust}/* 2>&1 | awk '(NR==1){print $1}'`
	if (test ! -s $testfile); then rm -rf ${ENS_SIZE}_${iclust}; break; fi
    done
  fi
done

rm tempgs101 #ensembles_size_[1-5].txt
