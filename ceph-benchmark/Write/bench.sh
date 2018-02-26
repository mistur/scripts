#!/bin/bash
#
# upload files of ${size}MB up to 1TB
# generate each file with openssl rand to have random content 
# save md5sum of each file
# push file into replicated pool
# push file into erasure code pool
# delete file
#
# keep the log of the comande to get upload time, speed and exec time of the upload commande (s3cmd or rclone)
#
# Argument :
#    bench.sh <file's size>

size=${1}
src_path=/dev/shm/ # using /dev/shm to avoid performance side effect of the disk speed 
dst_path=${size}MB/
number_files=$((1024*1024/size))
log_path=/data/log/${size}MB/

function gen_file() {
	size=$1
	src_path=$2
	file=$3
	block=$((size*1024*1024))
	cat /dev/null > ${src_path}${file}
	while [ ${block} -gt $((2048*1024*1024-1)) ] ; do
		openssl rand $((2048*1024*1024-1)) >> ${src_path}${file}
		block=$((block-(2048*1024*1024-1)))
	done
	openssl rand ${block} >> ${src_path}${file}
}

function push_s3_replicated () {
	file=$1
	src_path=$2
	dst_path=$3
	s3cmd --no-progress -c ~/.s3cfg-replicate-test put ${src_path}${file} s3://Replicated/${dst_path}${file} > ${log_path}${file}_put_replicated.log
	#rclone copy ${src_path}${file} testreplicated:Replicated/${dst_path}${file}  > ${log_path}${file}_put_replicated.log
}

function push_s3_erasure () {
	file=$1
	src_path=$2
	dst_path=$3
	s3cmd --no-progress -c ~/.s3cfg-erasure-test put ${src_path}${file} s3://Erasure/${dst_path}${file} > ${log_path}${file}_put_erasure.log
	#rclone copy ${src_path}${file} testerasure:Erasure/${dst_path}${file}  > ${log_path}${file}_put_replicated.log
} 


for ((i = 0 ; i < number_files ; i++ )); do
		file="${size}MB_${i}"
		echo $file
		gen_file ${size} ${src_path} ${file} 
		md5sum  ${src_path}${file} >  ${log_path}${file}.md5
		{ time -p push_s3_replicated ${file} ${src_path} ${dst_path} ; } 2> ${log_path}${file}_put_replicated.time  
		{ time -p push_s3_erasure ${file} ${src_path} ${dst_path} ; } 2> ${log_path}${file}_put_erasure.time 
		rm ${src_path}${file}
done


