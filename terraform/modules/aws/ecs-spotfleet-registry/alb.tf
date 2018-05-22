resource "aws_security_group" "ecs_alb" {
  description = "Balancer for ${var.app_name}"

  vpc_id = "${var.vpc_id}"
  name   = "${var.app_name}-alb-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "main" {
  name     = "${var.app_name}"
  port     = "${var.app_port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb" "main" {
  name                             = "${var.app_name}"
  subnets                          = ["${var.public_subnets}"]
  security_groups                  = ["${aws_security_group.ecs_alb.id}"]
  enable_cross_zone_load_balancing = false
  enable_http2                     = true
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.main.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.acm}"

  default_action {
    target_group_arn = "${aws_alb_target_group.main.id}"
    type             = "forward"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${var.route53_zone}"
  name    = "${var.fqdn}"
  type    = "A"

  alias {
    name                   = "${aws_alb.main.dns_name}"
    zone_id                = "${aws_alb.main.zone_id}"
    evaluate_target_health = true
  }
}
