variable vpc_id {}
variable public_subnets { type = "list" }
variable public_azs { type = "list" }

## public subnets for web server(s)
module "public_subnet" {
  source = "./public_subnet"
  vpc_id = "${var.vpc_id}"
  cidrs  = "${var.public_subnets}"
  azs    = "${var.public_azs}"
}

output "public_subnet_ids"  { value = "${module.public_subnet.subnet_ids}" }