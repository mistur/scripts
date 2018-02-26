#!/bin/bash

cluster=""

if [ -n "$1" ] ; then 
    cluster="--cluster $1"
fi

ceph $cluster pg dump | awk ' /^PG_STAT/ { col=1; while($col!="UP") {col++}; col++ } \
 /^[0-9a-f]+\.[0-9a-f]+/ { match($0,/^[0-9a-f]+/); pool=substr($0, RSTART, RLENGTH); poollist[pool]=0; \
 UP=$col; i=0; RSTART=0; RLENGTH=0; delete osds; while(match(UP,/[0-9]+/)>0) { osds[++i]=substr(UP,RSTART,RLENGTH); UP = \
substr(UP, RSTART+RLENGTH) } \
 for(i in osds) {array[osds[i],pool]++; osdlist[osds[i]];} \
} \
END { \
 printf("\n"); \
 printf("pool :\t"); for (i in poollist) printf("%s\t",i); printf("| SUM \n"); \
 for (i in poollist) printf("--------"); printf("----------------\n"); \
 sumosd=0; osd=0 ; for (i in osdlist) { osd+=1 ; printf("osd.%i\t", i); sum=0; \
   for (j in poollist) { printf("%i\t", array[i,j]); sum+=array[i,j]; sumosd+=array[i,j]; sumpool[j]+=array[i,j] }; \
printf("| %i\n",sum) } \
 for (i in poollist) printf("--------"); printf("----------------\n"); \
 printf("SUM :\t"); for (i in poollist) printf("%s\t",sumpool[i]);  printf("| %i\n",sumosd/osd); \
}'
