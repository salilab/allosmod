#!/bin/bash

TEMP=$1

FIL=allosmod.py
if (test ! -s ${FIL}); then echo ERROR for file: $FIL; exit; fi

LNRT=0
if test -e tempamct003; then rm tempamct003; fi
for NRT in `grep -n "MDtemp=" $FIL | awk 'BEGIN{FS=":"}{print $1}'`; do
    awk '(NR>'${LNRT}'&&NR<'${NRT}'){print $0}' $FIL >>tempamct003
    echo "    MDtemp="${TEMP}"    # temperature for the MD run" >>tempamct003
    LNRT=$NRT
done
awk '(NR>'${NRT}'){print $0}' $FIL >>tempamct003
mv tempamct003 $FIL
