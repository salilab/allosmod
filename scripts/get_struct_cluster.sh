#!/bin/bash
#inputs [12]_1/*.pdb and foxs_ens*.log 
#outputs grouped structures by similarity to best scoring set (2 to 5 member ensembles), also prints RMSD's to input structure and weights
#RMSD assignment by 1) find lowest RMSD for most_like_best, 2) find lowest RMSD for 2nd_most_like_best, 3)...

PM=$1 #input structure, column sort from lowest to highest RMSD to input 
if test -z $2; then #size of ensemble
    ESIZE=5
else
    ESIZE=$2
fi

for es in `echo $ESIZE | awk '{for(a=1;a<=$1;a++){print a}}'`; do
    esp1=$((${es} + 1))

    if (test ! -e foxs_ens${es}.log); then continue; fi

    R_BEST0=(`ls -1 ${es}_1/*pdb`)
    for s in ${R_BEST0[@]}; do
	/netapp/sali/allosmod/min_rmsd.sh $PM $s >>tempgsc_rmsd
    done
    R_BEST=(`sort -nk3 tempgsc_rmsd | awk '{print $2}'`)

    if test -e struct_cluster_${es}.out; then rm struct_cluster_${es}.out; fi
    for ifit in `echo 10 | awk '{for(a=1;a<=$1;a++){print a}}'`; do
	if (test ! -e ${es}_${ifit}); then continue; fi

	R_STRUCT=(`ls -1 ${es}_${ifit}/*pdb`)
	#get pairwise rmsd's
	rm tempgsc_rmsd
	for ibest in `echo $es | awk '{for(a=0;a<$1;a++){print a}}'`; do
	    for jstruct in `echo $es | awk '{for(a=0;a<$1;a++){print a}}'`; do
		/netapp/sali/allosmod/min_rmsd.sh ${es}_1/${R_BEST[${ibest}]} ${R_STRUCT[${jstruct}]} >>tempgsc_rmsd
	    done
	done
	#assign rmsd's
	for ibest in `echo $es | awk '{for(a=0;a<$1;a++){print a}}'`; do
	    sout=`awk '($1=="'${R_BEST[${ibest}]}'"){print $0}' tempgsc_rmsd |sort -nk3 | awk '(NR==1){print $2}'`
	    rout=`/netapp/sali/allosmod/min_rmsd.sh $PM ${es}_${ifit}/$sout | awk 'BEGIN{a=0.0}{a=$3}END{print a}'`
	    wout=`/netapp/sali/allosmod/pchop foxs_ens${es}.log $esp1 ${ifit} | grep $sout | awk 'BEGIN{a=1.0}{a=$3}END{print a}'`
	    echo -n ${sout}" "$rout" "$wout" " >>struct_cluster_${es}.out
	    awk '($2!="'${sout}'"){print $0}' tempgsc_rmsd > tempgsx412; mv tempgsx412 tempgsc_rmsd
	done
	echo "" >>struct_cluster_${es}.out
    done
done

rm tempgsc_rmsd 
