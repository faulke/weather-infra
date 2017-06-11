variable "vpc_id" {}
variable "my_ips" { type = "list" }
variable "max_size" { default = 1 }
variable "min_size" { default = 1 }
variable "desired_capacity" { default = 1 }
variable "loadbalancer_id" {}
variable "subnet_ids" { type = "list" }
variable "ami" {}
variable "key_name" {}
variable "stage" {}
variable "user_data" {}

# security group for autoscaling instances
resource "aws_security_group" "asg-web-sg" {
  name        = "tf-web-sg"
  description = "ec2 sg from terraform"
  vpc_id      = "${var.vpc_id}"

  # SSH from my ip
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ips}"]
  }

  # application port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# autoscaling group for public web servers
resource "aws_autoscaling_group" "asg" {
  lifecycle { create_before_destroy = true }

  name = "tf-asg-${var.stage}-${aws_launch_configuration.launch.name}"
  max_size = "${var.max_size}"
  min_size = "${var.min_size}"
  wait_for_elb_capacity = 1
  desired_capacity = "${var.desired_capacity}"
  health_check_grace_period = 300
  health_check_type = "ELB"
  launch_configuration = "${aws_launch_configuration.launch.id}"
  load_balancers = ["${var.loadbalancer_id}"]
  vpc_zone_identifier = ["${var.subnet_ids}"]
}

resource "aws_launch_configuration" "launch" {
    lifecycle { create_before_destroy = true }

    image_id = "${var.ami}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"

    security_groups = ["${aws_security_group.asg-web-sg.id}"]

    user_data = "${var.user_data}"
}