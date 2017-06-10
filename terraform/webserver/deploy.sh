#!/usr/bin/env bash
echo $1
export AMI="$(aws ec2 describe-images --filters Name=tag:Version,Values=$1 --query Images[0].[ImageId] --output text)"
export AWS_ACCESS_KEY=$2
export AWS_SECRET_KEY=$3
echo $AMI


terraform plan -var ami=$AMI -var access_key=$AWS_ACCESS_KEY -var secret_key=$AWS_SECRET_KEY
terraform apply -var ami=$AMI
