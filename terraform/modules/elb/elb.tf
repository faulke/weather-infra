variable vpc_id {}
variable name {}
variable subnets { type = "list" }
variable instance_port { default = 3000 }
variable ssl_cert {}

## elb security group
resource "aws_security_group" "elb-sg" {
  name        = "tf-${var.name}-sg"
  description = "elb sg from terraform"
  vpc_id      = "${var.vpc_id}"

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #todo: dynamic ingress cidrs for staging
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


## create elasic load balancer
resource "aws_elb" "elb" {
  name            = "tf-${var.name}"
  subnets         = ["${var.subnets}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]

  listener {
    instance_port     = "${var.instance_port}"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = "${var.instance_port}"
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.ssl_cert}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    target              = "HTTP:3000/index.html"
    interval            = 10
  }
}

output "elb_id" { value = "${aws_elb.elb.id}" }
output "dns_name" { value = "${aws_elb.elb.dns_name}" }
output "zone_id" { value = "${aws_elb.elb.zone_id}" }