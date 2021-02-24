#!/bin/bash

#method="PUT"
#canonical_uri="<BUCKET_PATH>/${RANDOM}.jpg"
#file_name="<IMAGE_NAME>"


method=$1
canonical_uri=$2
file_name=$3


access_key=$(jq -r ".Credentials.AccessKeyId" ./sts.txt)
secret_key=$(jq -r ".Credentials.SecretAccessKey" ./sts.txt)
amz_security_token=$(jq -r ".Credentials.SessionToken" ./sts.txt)

#Singapore s3 uri
host="s3.ap-southeast-1.amazonaws.com"

#ZHY s3 uri
#host="s3.cn-northwest-1.amazonaws.com.cn"

#x_amz_date=`date "+%Y%m%dT%H%M%SZ"`
#date_stamp=`date "+%Y%m%d"`

x_amz_date=`date -u "+%Y%m%dT%H%M%SZ"`
date_stamp=`date -u "+%Y%m%d"`


region="ap-southeast-1"
#region="cn-northwest-1"

service="s3"
request="aws4_request"

create_canonical_request() {
	canonical_headers="host:${host}\nx-amz-date:${x_amz_date}\nx-amz-security-token:${amz_security_token}\n"
	signed_headers="host;x-amz-date;x-amz-security-token"
	payload_hash="UNSIGNED-PAYLOAD"
	canonical_request="${method}\n${canonical_uri}\n\n${canonical_headers}\n${signed_headers}\n${payload_hash}"
#	echo -en $canonical_request
}

create_string_to_sign() {
	algorithm="AWS4-HMAC-SHA256"
	credential_scope="${date_stamp}/${region}/${service}/${request}"
	canonical_request_hash=$(echo -en ${canonical_request} | openssl dgst -sha256 | awk '{print $2}')
	string_to_sign="${algorithm}\n${x_amz_date}\n${credential_scope}\n${canonical_request_hash}"
#	echo -en $string_to_sign
}

create_signing_key() {
	key="AWS4${secret_key}"

	key_d=$(echo -en ${date_stamp} | openssl dgst -sha256 -hmac ${key} | awk '{print $2}')

	key_r=$(echo -en ${region} | openssl dgst -sha256 -mac HMAC -macopt hexkey:${key_d} | awk '{print $2}')
	
	key_s=$(echo -en ${service} | openssl dgst -sha256 -mac HMAC -macopt hexkey:${key_r} | awk '{print $2}')

	key_r=$(echo -en ${request} | openssl dgst -sha256 -mac HMAC -macopt hexkey:${key_s} | awk '{print $2}')
}

usage() {
	echo usage ---------------------------------------------------------------
	echo s3.sh [method] [uri] [file_name]
	echo s3.sh GET /bucket/object output_file
	echo s3.sh PUT /bucket/object input_file
	echo usage ---------------------------------------------------------------
}

send_request() {
	create_canonical_request
	create_string_to_sign
	create_signing_key
	
	signature=$(echo -en ${string_to_sign} | openssl dgst -sha256 -mac HMAC -macopt hexkey:${key_r} | awk '{print $2}')
	credential="${access_key}/${date_stamp}/${region}/${service}/${request}"
	signed_headers="host;x-amz-date;x-amz-security-token"
	
	if [ $method == "PUT" ]; then
		file_size=$(stat -c%s "$file_name")
		
		curl -s -v -X PUT "http://${host}${canonical_uri}" \
		-H "Host: ${host}" \
		-H "x-amz-date: ${x_amz_date}" \
		-H "x-amz-security-token: ${amz_security_token}" \
		-H "Authorization: AWS4-HMAC-SHA256 Credential=${credential}, SignedHeaders=${signed_headers}, Signature=${signature}" \
		-H "x-amz-content-sha256: UNSIGNED-PAYLOAD" \
		-H "Content-Length: ${file_size}" \
		-T "${file_name}" 
		
	elif [ $method == "GET" ]; then
		curl -s -v -X GET "http://${host}${canonical_uri}" \
		-H "Host: ${host}" \
		-H "x-amz-content-sha256: UNSIGNED-PAYLOAD" \
		-H "x-amz-security-token: ${amz_security_token}" \
		-H "Authorization: AWS4-HMAC-SHA256 Credential=${credential}, SignedHeaders=${signed_headers}, Signature=${signature}" \
		-H "x-amz-date: ${x_amz_date}" \
		-o "${file_name}" 
		
	else 
		usage
	fi	
}

send_request


