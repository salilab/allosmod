#!/bin/bash

#fix output2.zip, allow deleted files, get rid of gmail req
EMAIL=`awk '($1=="email"){print $2}' output/input/foxs.in`
if test $EMAIL == "pweinkam@gmail.com"; then 

#run from directory in which all runs have been collected into single directory called output (allosmod postprocessing)
PWD0=`pwd`
JOBNAME=`pwd | awk '{print "dirname "$0}' |sh | awk '{print "basename "$0}' |sh`

cd output/

if test -s input/saxs.dat; then #allosmod-foxs run
    cp input/saxs.dat $PWD0

    #process files to send to FoXS
    #get pdbs
    mkdir ${PWD0}/send
    cp input/struct_cluster_*.out ${PWD0}/send/
    head -n1 input/struct_cluster_*.out | grep pdb | awk '{for(a=1;a<=NF;a++){if(a%3==1){print "cp input/"$a" '${PWD0}'/send/"}}}' |sh
    R_ENS=(  1 2 2 3 3 3 4 4 4 4 )
    R_CLUST=(1 1 2 1 2 3 1 2 3 4 )
    ctr=-1
    for ens in ${R_ENS[@]}; do
	ctr=$((${ctr} + 1))
	clust=${R_CLUST[${ctr}]}
	awk 'BEGIN{printf "/netapp/sali/allosmod/pdb_merge.pl"}{printf " input/"$('${clust}'*3-2)}\
             END{printf " >'${PWD0}'/send/ens_'${ens}'_clust_'${clust}'.pdb\n"}' input/struct_cluster_${ens}.out |sh
    done
    #get fit results
    cp input/ensemble_size*_1.dat ${PWD0}/send/
    R_CHI=(`head -n1 input/foxs_ens*log | awk 'BEGIN{a=1}(NF==5){print $2;a+=1}'` 0.000 0.000 0.000 0.000 )
    R_AVGQ=(`awk 'BEGIN{a=0;b=0;c=0;nc=0;d=0;nd=0;e=0;ne=0}\
           (NR==1){a=$2}(NR==2){b=$2}\
           (NR>=3&&NR<=4){c+=$2;nc+=1}\
           (NR>=5&&NR<=7){d+=$2;nd+=1}\
           (NR>=8&&NR<=10){e+=$2;ne+=1}\
           END{if(nc==0){nc=1};if(nd==0){nd=1};if(ne==0){ne=1};\
           printf "%7.2f%7.2f%7.2f%7.2f%7.2f\n",a,b,c/nc,d/nd,e/ne}' input/newstate*cq*`)
    echo 1.0 ${R_CHI[0]} ${R_AVGQ[0]} >${PWD0}/send/enssize_chi_qab.dat
    echo 2.0 ${R_CHI[1]} ${R_AVGQ[1]} >>${PWD0}/send/enssize_chi_qab.dat
    echo 3.0 ${R_CHI[2]} ${R_AVGQ[2]} >>${PWD0}/send/enssize_chi_qab.dat
    echo 4.0 ${R_CHI[3]} ${R_AVGQ[3]} >>${PWD0}/send/enssize_chi_qab.dat

    #process simulation trajectories
    for dir in `ls -1d input/pred_dE*/*_[0-9]` `ls -1d input/pred_dE*/*_[0-9][0-9]`; do
	if test -d $dir; then
	    #rm -rf $dir
	    rm ${dir}/*.rsr ${dir}/*py ${dir}/*log ${dir}/*.pyc ${dir}/atomlistASRS ${dir}/allostericsite.pdb ${dir}/contacts.dat ${dir}/lig.pdb ${dir}/break.dat
	    rm -rf ${dir}/pred_*
	    rm ${dir}/pm.pdb.B[09]* ${dir}/pm.pdb.[DVis]* ${dir}/ensembles_size_*
	fi
    done
#    rm input/*.pdb input/*pdb.dat input/allosmodfox input/newstate* input/list* input/foxs.in input/filenames 

    #zip only relevant structures for FoXS
    cd $PWD0
    zip -r send.zip send
    sleep 1m
    zip -r output2.zip output
    sleep 1m
    
    #get FoXS output page
####this needs to be changed to script that inputs pdbs and profiles and outputs webpage
#    /modbase5/home/foxs/www/foxs/cgi/input_call.pl output.zip saxs.dat >& foxs.log

#    grep "http:" foxs.log | tail -n1 > urlout
#    if (test ! -s urlout); then 
#	echo fail >urlout #if job did not complete properly
#    fi

    rm -rf output send
#    rm send.zip
else
    #regular allosmod run
    cd $PWD0
    #collect energies
    ls -1d output/*/pred_dE* | awk '{print "echo "$1" >list\n/netapp/sali/allosmod/get_e.sh"}' |sh
    zip -r output.zip output
    echo "nofoxs" > urlout

    sleep 1m
    rm -rf output
fi


fi