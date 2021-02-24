#!/bin/bash
aws sts assume-role --role-arn arn:aws-cn:iam::<ACCOUNT_ID>:role/<ROLE_NAME>  --role-session-name $1 > sts.txt

cat sts.txt
