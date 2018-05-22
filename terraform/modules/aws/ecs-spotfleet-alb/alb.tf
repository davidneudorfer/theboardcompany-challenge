resource "aws_security_group" "ecs_alb" {
  description = "Balancer for ${var.app_name}"

  vpc_id = "${var.vpc}"
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

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.alb_log_bucket_name}"
  region = "${var.region}"
  acl    = "private"

  tags {
    Name        = "${var.alb_log_bucket_name}"
    Environment = "${var.environment}"
    Terraform   = "true"
  }

  policy = <<POLICY
{
  "Id": "Policy1526929955653",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1526929949208",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.alb_log_bucket_name}/*/AWSLogs/725725810126/*",
      "Principal": {
        "AWS": [
          "797873946194"
        ]
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.alb_logs.id}"

  lambda_function {
    lambda_function_arn = "${module.alb_logcollector.arn}"
    events              = ["s3:ObjectCreated:*"]

    # FIXME: test filter prefix
    # filter_prefix       = "AWSLogs/"
    # filter_suffix       = ".gz"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${var.route53_zone}"
  name    = "${var.fqdn}"
  type    = "A"

  # name                   = "${aws_alb.main.dns_name}"
  # zone_id                = "${aws_alb.main.zone_id}"

  alias {
    name                   = "${module.alb.dns_name}"
    zone_id                = "${module.alb.load_balancer_zone_id}"
    evaluate_target_health = true
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/3.4.0
module "alb" {
  source                   = "terraform-aws-modules/alb/aws"
  version                  = "3.4.0"
  load_balancer_name       = "${var.app_name}"
  security_groups          = ["${aws_security_group.ecs_alb.id}"]
  log_bucket_name          = "${aws_s3_bucket.alb_logs.bucket}"
  log_location_prefix      = "${var.app_name}-alb"
  subnets                  = ["${var.public_subnets}"]
  tags                     = "${map("Environment", "${var.environment}")}"
  vpc_id                   = "${var.vpc}"
  https_listeners          = "${list(map("certificate_arn", "${var.acm}", "port", 443))}"
  https_listeners_count    = "1"
  http_tcp_listeners       = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count = "1"
  target_groups            = "${list(map("name", "${var.app_name}", "backend_protocol", "HTTP", "backend_port", "80"))}"
  target_groups_count      = "1"
}
