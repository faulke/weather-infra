## configure aws provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

## create public subnets in different AZs
resource "aws_subnet" "weather-public-a" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags {
    Name = "weather-public-a"
  }
}

resource "aws_subnet" "weather-public-b" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags {
    Name = "weather-public-b"
  }
}

## associate subnets with public route table
resource "aws_route_table_association" "tf-rta-weather-public-a" {
  subnet_id      = "${aws_subnet.weather-public-a.id}"
  route_table_id = "${var.route_table_id}"
}

resource "aws_route_table_association" "tf-rta-weather-public-b" {
  subnet_id      = "${aws_subnet.weather-public-b.id}"
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
  subnets         = ["${aws_subnet.weather-public-a.id}", "${aws_subnet.weather-public-b.id}"]
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
    timeout             = 5
    target              = "HTTP:3000/index.html"
    interval            = 10
  }
}

# Send simpleweather.us to the load balancer
resource "aws_route53_record" "simpleweather-us" {
  zone_id = "${var.zone_id}"
  name    = "simpleweather.us"
  type    = "A"

  alias {
    zone_id                = "${aws_elb.weather-elb.zone_id}"
    name                   = "${aws_elb.weather-elb.dns_name}."
    evaluate_target_health = false
  }
}

resource "aws_autoscaling_group" "asg-weather" {
  lifecycle { create_before_destroy = true }

  name = "asg-weather - ${aws_launch_configuration.lc-weather.name}"
  max_size = 1
  min_size = 1
  wait_for_elb_capacity = 1
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  launch_configuration = "${aws_launch_configuration.lc-weather.id}"
  load_balancers = ["${aws_elb.weather-elb.id}"]
  vpc_zone_identifier = ["${aws_subnet.weather-public-a.id}", "${aws_subnet.weather-public-b.id}"]
}

resource "aws_launch_configuration" "lc-weather" {
    lifecycle { create_before_destroy = true }

    image_id = "${var.ami}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"

    security_groups = ["${aws_security_group.weather-ec2-sg.id}"]

    user_data = "${file("./user-data.sh")}"
}
