#!/usr/bin/env bash

# get base webserver image
export AMI="$(aws ec2 describe-images --filters Name=tag:Name,Values=WebServerBase --query Images[0].[ImageId] --output text)"

#set version env variable for packer
export VERSION=$1

echo "${AMI}"
echo ${VERSION}
echo ${SOURCE}

# validate packer script prior to build
packer validate app-packer.json

packer build app-packer.json

# set TC parameter for deploy build config
echo "##teamcity[setParameter name='env.VERSION' value='$VERSION']"
