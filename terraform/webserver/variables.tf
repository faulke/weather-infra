variable "access_key" {}
variable "secret_key" {}

## ami specified in command line
variable "ami" {}

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
  default = "rtb-daea0dbc"
}

# acm ssl certificate for elb
variable "acm_ssl_arn" {
  default = "arn:aws:acm:us-west-2:580022145584:certificate/3cd571c1-ab7a-4026-9db9-0744fdecc607"
}

# my public ip
variable "my_ip" {
  default = "72.175.141.138/32"
}

variable "zone_id" {
  default = "ZB03J4AOJ2K1B"
}
