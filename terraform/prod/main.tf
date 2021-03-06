## s3 backend
terraform {
  backend "s3" {
    bucket = "weather-infra"
    key    = "prod/terraform.tfstate"
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
module "weather_vpc" {
  source         = "../modules/vpc"
  vpc_cidr       = "${var.vpc_cidr}"
  vpc_name       = "${var.vpc_name}"
  public_subnets = "${var.public_subnets}"
  public_azs     = "${var.public_azs}"
}

## production load balancer
module "prod_elb" {
  source   = "../modules/elb"
  vpc_id   = "${module.weather_vpc.vpc_id}"
  name     = "${var.prod_elb_name}"
  subnets  = "${module.weather_vpc.public_subnet_ids}"
  ssl_cert = "${var.acm_ssl_arn}"
}

## autoscaling group for public web servers
module "weather_asg" {
  source          = "../modules/asg"
  vpc_id          = "${module.weather_vpc.vpc_id}"
  stage           = "prod"
  my_ips          = "${var.my_ips}"
  loadbalancer_id = "${module.prod_elb.elb_id}"
  subnet_ids      = "${module.weather_vpc.public_subnet_ids}"
  ami             = "${var.ami}"
  key_name        = "${var.key_name}"
  user_data       = "${file("./user-data.sh")}"
}

## route53 records for prod_elb
resource "aws_route53_record" "simpleweather-us" {
  zone_id = "${var.zone_id}"
  name    = "simpleweather.us"
  type    = "A"

  alias {
    zone_id                = "${module.prod_elb.zone_id}"
    name                   = "${module.prod_elb.dns_name}."
    evaluate_target_health = false
  }
}