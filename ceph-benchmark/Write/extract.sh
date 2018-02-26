#!/bin/bash

size=$1
number_files=$((1024*1024/size))
log_path=/data/log/${size}MB/

echo "file name;file size;commande duration;copy duration;speed;speed unit" > /data/log/${size}MB_replicated.csv
echo "file name;file;size;commande duration;copy duration;speed;speed unit" > /data/log/${size}MB_erasure.csv

for i in ` seq 0 $((number_files-1)) `  ; do
#for i in {0..16383} ; do
#for i in {0..32767} ; do

	file=${size}MB_${i}
	log_file_replicated="${log_path}${size}MB_${i}_put_replicated.log"
	log_file_erasure="${log_path}${size}MB_${i}_put_erasure.log"
	time_file_replicated="${log_path}${size}MB_${i}_put_replicated.time"
	time_file_erasure="${log_path}${size}MB_${i}_put_erasure.time"
	
	time_copy_replicated=`cat $log_file_replicated | awk '{ print $8 "s;" $10 ";" $11}' | sed 's/)//;s/s;/;/'`
	time_copy_erasure=`cat $log_file_erasure | awk '{ print $8 "s;" $10 ";" $11}' | sed 's/)//;s/s;/;/'`
	time_s3cmd_replicated=`cat $time_file_replicated | awk '/real/ { print $2}' | sed 's/0m//;s/s//'`
	time_s3cmd_erasure=`cat $time_file_erasure | awk '/real/ { print $2}' | sed 's/0m//;s/s//'`

	echo "$file;$((size*1024*1024));$time_s3cmd_replicated;$time_copy_replicated" >> /data/log/${size}MB_replicated.csv
	echo "$file;$((size*1024*1024));$time_s3cmd_erasure;$time_copy_erasure" >> /data/log/${size}MB_erasure.csv

done


