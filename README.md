# weather-infra
Cloud infrastructure, build, and deployment scripts for weatherapp (https://github.com/faulke/weatherapp).

# Description
This repo is used to manage cloud infrastructure of for my simple React-Redux [weatherapp](https://github.com/faulke/weatherapp).

## Infrastructure
Infrastructure is hosted on AWS and managed by [Terraform](https://github.com/hashicorp/terraform), a popular open source tool by
[Hashicorp](https://www.hashicorp.com/) for managing infrastructure as code.  The basic infrastructure consists of two VPCs: staging
and production.  Each VPC is identical with two public subnets in two different availability zones (AZs). Traffic is served by an Elastic
Load Balancer in multiple AZs to an auto scaling group of EC2 instances where the weather app is running.  This sort of design offers
a few different advantages:
  1) Having a staging VPC that is identical to production allows testing changes to infrastructure (and the weather app) in a safe environment before making
  changes to production.
  2) Multiple AZs provide redundancy and high availability.
  3) Auto scaling groups will scale up and down by adding more EC2 resources depending on variety of metrics, including CPU load.
  
Route53 records route traffic to staging (https://staging.simpleweather.us) and production (https://simpleweather.us).

## Build and Deploy Pipeline
The build and deploy process is managed by a [TeamCity](https://www.jetbrains.com/teamcity/). Hashicorp's [Packer](https://github.com/hashicorp/packer) 
builds AMIs, and Terraform is utilized for deployment.

The basic process is as follows:
  1) Packer builds a base web server AMI with Nodejs.  This only needs to be done every couple weeks when new base AMIs are available
  from AWS.
  2) A Build configuration builds static assets and produces an artifact of the built application based on a specific application revision
  (in this case, a Github release) in a .zip archive.
  3) Packer uses the base web server AMI to build an application AMI with the application unzipped into a `weatherapp/` directory and dependencies
  installed.  At this point, the application AMI is "environment agnostic" and can be deployed to either staging (preferred) or production.
  4) A deploy script retrieves the application AMI ID and updates the auto scaling group with the new image. This forces a new auto scaling group
  to be deployed. By utilizing a `create_before_destroy` lifecycle hook, the old web server is not destroyed until the new application server
  becomes available. A `user_data` script on launch pulls environment variables from S3 depending on staging vs. production.
  
This process provides a few advantages:
  1) The entire "build and deploy" process is relatively fast (~ 10 minutes).
  2) Zero down time during deployment.
  3) Web servers are immutable.
  4) Easily roll back to a previous revision by simply deploying a previous application AMI.
  
One big disadvantage:
  1) The [deploy](./terraform/prod/deploy.sh) script runs a `terraform apply`, which checks for changes to the entire infrastructure for the environment, so there is a
  potential for unwanted changes to be made to other parts of the infrastructure.  With this small of an application, I'm not too worried
  about it, but maybe fail safes could be added to ensure the build server doesn't change any other part of the infrastructure besides
  auto scaling groups.

# Next
- Specify a dedicated public subnet for Packer build instances.
- Don't launch web servers with public IP address, but instead create a private subnet with bastion host for SSHing to web servers. 
- Limit traffic to staging by IP address, so the public can't view it.
- Epic: Switch from TeamCity to a Jenkins or Concourse.ci build server (because pipelines are nice).
  
