# account credentials
variable "access_key" {}
variable "secret_key" {}

# default region
variable "aws_region" {
  default = "us-west-2"
}

# weather vpc id
variable "vpc_id" {
  default = "vpc-8d96eeea"
}

# public subnet cidr blocks
variable "public_subnets" {
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

# public availability zones
variable "public_azs" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "prod_elb_name" {
  default = "prod-elb"
}

# acm ssl certificate for elb
variable "acm_ssl_arn" {
  default = "arn:aws:acm:us-west-2:580022145584:certificate/3cd571c1-ab7a-4026-9db9-0744fdecc607"
}

# my public ip
variable "my_ips" {
  default = ["72.175.141.138/32", "184.166.70.170/32"]
}

variable "ami" {
  default = "ami-08c4cd71"
}

variable "zone_id" {
  default = "ZB03J4AOJ2K1B"
}

variable "key_name" {
  default = "build_keys"
}
