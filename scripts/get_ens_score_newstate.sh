#!/bin/bash
#input struct_cluster_[23].out and [12]_* structures for "best fit" ensemble, outputs qmatrix scores for structures that might be a "new state"
#assignment of new state is that which is most dissimilar from input structure
#ignore states with weights < 5 %
#max 10 structures in each cluster (hard cutoff for get_qmatrix)

FIL_PM=$1

if (test ! -e struct_cluster_2.out); then echo struct_cluster_2.out missing; exit; fi
if (test ! -e ${FIL_PM}); then echo ${FIL_PM} missing; exit; fi

#get 1 state prediction
mkdir tempfc321
ls -1 1_[0-9]/*.pdb 1_10/*.pdb | awk '{print "cp "$1" tempfc321"}' |sh
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate1_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate1_qmatrix.dat
cd ..

rm tempfc321/*
#get 2 state prediction, using structural clustering
if test -e struct_cluster_2.out; then
F_2STATE=(`awk '($3>=0.05&&$6>=0.05){print $4}' struct_cluster_2.out`)

for s in ${F_2STATE[@]}; do
    ls -1 2_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate2_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate2_qmatrix.dat
cd ..
fi
rm tempfc321/*
#get 3 state prediction, using structural clustering
if test -e struct_cluster_3.out; then
F_3STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05){print $4}' struct_cluster_3.out`)
for s in ${F_3STATE[@]}; do
    ls -1 3_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate3a_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate3a_qmatrix.dat
cd ..
rm tempfc321/*
F_3STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05){print $7}' struct_cluster_3.out`)
for s in ${F_3STATE[@]}; do
    ls -1 3_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate3b_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate3b_qmatrix.dat
cd ..
fi
#get 4 state prediction, using structural clustering
if test -e struct_cluster_4.out; then
F_4STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05){print $4}' struct_cluster_4.out`)
for s in ${F_4STATE[@]}; do
    ls -1 4_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate4a_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate4a_qmatrix.dat
cd ..
rm tempfc321/*
F_4STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05){print $7}' struct_cluster_4.out`)
for s in ${F_4STATE[@]}; do
    ls -1 4_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate4b_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate4b_qmatrix.dat
cd ..
rm tempfc321/*
F_4STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05){print $10}' struct_cluster_4.out`)
for s in ${F_4STATE[@]}; do
    ls -1 4_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate4c_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate4c_qmatrix.dat
cd ..
fi
#get 5 state prediction, using structural clustering
if test -e struct_cluster_5.out; then
F_5STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05&&$15>=0.05){print $4}' struct_cluster_5.out`)
for s in ${F_5STATE[@]}; do
    ls -1 5_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate5a_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate5a_qmatrix.dat
cd ..
rm tempfc321/*
F_5STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05&&$15>=0.05){print $7}' struct_cluster_5.out`)
for s in ${F_5STATE[@]}; do
    ls -1 5_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate5b_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate5b_qmatrix.dat
cd ..
rm tempfc321/*
F_5STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05&&$15>=0.05){print $10}' struct_cluster_5.out`)
for s in ${F_5STATE[@]}; do
    ls -1 5_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate5c_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate5c_qmatrix.dat
cd ..
rm tempfc321/*
F_5STATE=(`awk '($3>=0.05&&$6>=0.05&&$9>=0.05&&$12>=0.05&&$15>=0.05){print $13}' struct_cluster_5.out`)
for s in ${F_5STATE[@]}; do
    ls -1 5_*/$s | awk '{print "cp "$1" tempfc321"}' |sh
done
cd tempfc321
allosmod get_qmatrix ../$FIL_PM 11.0 *.pdb
mv cq_aq_qavg_qsd.dat ../newstate5d_cq_aq_qavg_qsd.dat
mv qmatrix.dat ../newstate5d_qmatrix.dat
cd ..
fi

rm -rf tempfc321 tempgesn4221

