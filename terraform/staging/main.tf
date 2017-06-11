## s3 backend
terraform {
  backend "s3" {
    bucket = "weather-infra"
    key    = "staging/terraform.tfstate"
    region = "us-west-2"
  }
}

## configure aws provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

## set up vpc (public/private subnets, route tables, igw)
module "staging_vpc" {
  source         = "../modules/vpc"
  vpc_id         = "${var.vpc_id}"
  public_subnets = "${var.public_subnets}"
  public_azs     = "${var.public_azs}"
}

## production load balancer
module "staging_elb" {
  source   = "../modules/elb"
  vpc_id   = "${var.vpc_id}"
  name     = "${var.staging_elb_name}"
  subnets  = "${module.staging_vpc.public_subnet_ids}"
  ssl_cert = "${var.acm_ssl_arn}"
}

## autoscaling group for public web servers
module "weather_asg" {
  source          = "../modules/asg"
  vpc_id          = "${var.vpc_id}"
  stage           = "staging"
  my_ips          = "${var.my_ips}"
  loadbalancer_id = "${module.staging_elb.elb_id}"
  subnet_ids      = "${module.staging_vpc.public_subnet_ids}"
  ami             = "${var.ami}"
  key_name        = "${var.key_name}"
  user_data       = "${file("./user-data.sh")}"
}

## route53 records for prod_elb
resource "aws_route53_record" "staging-simpleweather-us" {
  zone_id = "${var.zone_id}"
  name    = "staging"
  type    = "CNAME"

  records = ["${module.staging_elb.dns_name}"]
}