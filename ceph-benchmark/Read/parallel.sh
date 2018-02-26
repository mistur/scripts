#!/bin/bash

#cycle=1
#parallel=1
cycle=$1
parallel=$2

for (( i = 1 ; i < ${cycle} ; i++)); do echo "" ; done | parallel -P ${parallel} bash ./readbench.sh 4096
