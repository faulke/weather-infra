#!/usr/bin/env bash
echo $1
export AMI="$(aws ec2 describe-images --filters Name=tag:Version,Values=$1 --query Images[0].[ImageId] --output text)"
echo $AMI

terraform plan -var ami=$AMI
terraform apply -var ami=$AMI
