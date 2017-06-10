#!/usr/bin/env bash
echo $1
export AMI="$(aws ec2 describe-images --filters Name=tag:Version,Values=$1 --query Images[0].[ImageId] --output text)"
echo $AMI

terraform plan -var ami=$AMI -var access_key=$2 -var secret_key=$3
terraform apply -var ami=$AMI
