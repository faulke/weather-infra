variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  default = "us-west-2"
}

# name of private key to associate with instance
variable "key_name" {
  default = "build_keys"
}

# weather vpc
variable "vpc_id" {
  default = "vpc-8d96eeea"
}

# custom route table for weather vpc
variable "route_table_id" {
  default = "rtb-dbea0dbd"
}

# public subnet
variable "public_subnet_id" {
  default = "subnet-5766f730"
}

# acm ssl certificate for elb
variable "acm_ssl_arn" {
  default = "arn:aws:acm:us-west-2:580022145584:certificate/3cd571c1-ab7a-4026-9db9-0744fdecc607"
}

# linux ami for us-west-2
variable "ami" {
  default = "ami-8ca83fec"
}

# my public ip
variable "my_ip" {
  default = "72.175.141.138/32"
}
