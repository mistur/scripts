#!/bin/bash
#
#source ./readbench.conf

size=$1
tsize=(32 64 128 256 512 1024 2048 4096);
dst_path=/dev/shm/ # using /dev/shm to avoid performance side effect of the disk speed 
log_path=/tmp/rlog/${size}MB/
mkdir -p ${log_path}

# get_rtrn
#    get return result part
# params:
#    $1 - return result string
#    $2 - number of part to be returned
# returns:
#    return result part
function get_rtrn(){
    echo `echo $1|cut --delimiter=, -f$2`
}


# gen file name
# if a size is passed in arg[1] then get only file with that size
function random_file_name() {

    fsize=$1
    test -n "${fsize}" || fsize=${tsize[$((RANDOM % 8))]}
    num=$((RANDOM % (1024*1024/fsize)))
    echo "${fsize},${num}"

}

# file=`random_file_name`
# echo ${file}

function copy_s3_replicated () {
	file=$1
	src_path=$2
	dst_path=$3
	#s3cmd --no-progress -c ~/.s3cfg-replicate-test get s3://Replicated/${dst_path}${file} ${src_path}${file} > ${log_path}${file}_put_replicated.log
	rclone copy --log-file ${log_path}${file}_copy_replicated.log testreplicated:Replicated/${src_path}${file} ${dst_path}
}

function copy_s3_erasure () {
	file=$1
	src_path=$2
	dst_path=$3
	#s3cmd --no-progress -c ~/.s3cfg-erasure-test put ${src_path}${file} s3://Erasure/${dst_path}${file} > ${log_path}${file}_put_erasure.log
	rclone copy --log-file ${log_path}${file}_copy_replicated.log testerasure:Erasure/${src_path}${file} ${dst_path} 
} 

function check_md5sum () {
	file=$1
	src_path=$2
	dst_path=$3
    rclone copy --log-file /dev/null testreplicated:Replicated/md5sum/${src_path}${file}.md5 ${dst_path}
    if md5sum -c ${dst_path}${file}.md5 > /dev/null ; then
       echo "${file} OK"
    else
       echo "${file} KO"
    fi

}


function read_one() {
 
        rfile=`random_file_name ${size}`
        size=`get_rtrn $rfile 1`
        file=${size}MB_`get_rtrn $rfile 2`
        src_path=${size}MB/
        log_path=/tmp/rlog/${size}MB/
        mkdir -p ${log_path}

        echo copy_s3_replicated ${file} ${src_path} ${dst_path} 
		{ time -p copy_s3_replicated ${file} ${src_path} ${dst_path} ; } 2>> ${log_path}${file}_read_replicated.time  
        test -n "${checksum}" && check_md5sum ${file} ${src_path} ${dst_path} >> ${log_path}check_replicated.log
        rm ${dst_path}${file}

        #echo copy_s3_erasure ${file} ${src_path} ${dst_path}
		#{ time -p copy_s3_erasure ${file} ${src_path} ${dst_path} ; } 2>> ${log_path}${file}_read_erasure.time 
        #test -n "${checksum}" && check_md5sum ${file} ${src_path} ${dst_path} >> ${log_path}check_erasure.log
        #rm ${dst_path}${file}

}

read_one


