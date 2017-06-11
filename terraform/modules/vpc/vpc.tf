variable vpc_cidr {}
variable vpc_name {}
variable public_subnets { type = "list" }
variable public_azs { type = "list" }

## create vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"

  tags      { Name = "${var.vpc_name}" }
  lifecycle { create_before_destroy = true }
} 

## public subnets for web server(s)
module "public_subnet" {
  source = "./public_subnet"
  vpc_id = "${aws_vpc.vpc.id}"
  cidrs  = "${var.public_subnets}"
  azs    = "${var.public_azs}"
}

output "vpc_id" { value = "${aws_vpc.vpc.id}" }
output "public_subnet_ids"  { value = "${module.public_subnet.subnet_ids}" }