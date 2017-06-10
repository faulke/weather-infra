#!/usr/bin/env bash
echo $1

# initialize ami id variable
AMI="None"

# try getting AMI id until it is available
until [ $AMI != "None" ]; do
  echo "Fetching AMI."
  AMI="$(aws ec2 describe-images --filters Name=tag:Version,Values=$1 --query Images[0].[ImageId] --output text)"
  done

echo $AMI

terraform --version

# get tfstate from s3 backend
terraform init

# validate plan
terraform plan -var ami=$AMI -var access_key=$AWS_ACCESS_KEY_ID -var secret_key=$AWS_SECRET_ACCESS_KEY

# apply plan -- deploy
terraform apply -var ami=$AMI -var access_key=$AWS_ACCESS_KEY_ID -var secret_key=$AWS_SECRET_ACCESS_KEY
