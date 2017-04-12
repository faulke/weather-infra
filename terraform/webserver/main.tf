## configure aws provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

## create public subnet a
resource "aws_subnet" "weather-public" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
}

## associate subnet with public route table
resource "aws_route_table_association" "tf-rta-weather-public" {
  subnet_id      = "${aws_subnet.weather-public.id}"
  route_table_id = "${var.route_table_id}"
}

resource "aws_security_group" "weather-elb-sg" {
  name        = "tf-weather-elb-sg"
  description = "elb sg from terraform"
  vpc_id      = "${var.vpc_id}"

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
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

## security group for web server
resource "aws_security_group" "weather-ec2-sg" {
  name        = "tf-weather-ec2-sg"
  description = "ec2 sg from terraform"
  vpc_id      = "${var.vpc_id}"

  # SSH from my ip
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}", "184.166.70.170/32"]
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

## create elasic load balancer
resource "aws_elb" "weather-elb" {
  name            = "tf-weather-elb"
  subnets         = ["${aws_subnet.weather-public.id}"]
  security_groups = ["${aws_security_group.weather-elb-sg.id}"]

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 3000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.acm_ssl_arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 29
    target              = "HTTP:3000/index.html"
    interval            = 30
  }

  instances = ["${aws_instance.weather-ec2.id}"]
}

## output the elb dns
output "elb_dns" {
  value = "${aws_elb.weather-elb.dns_name}"
}

## create base web server ec2 instance
resource "aws_instance" "weather-ec2" {
  instance_type = "t2.micro"
  ami           = "${var.ami}"

  tags {
    Name = "tf-weather-app-server"
  }

  # key name for SSH access
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.weather-ec2-sg.id}"]

  subnet_id = "${aws_subnet.weather-public.id}"

  user_data = "sudo yum update -y"
}
