terraform {
  required_version = "> 0.10"

  #FUTURE (https://github.com/hashicorp/terraform/issues/16835)
  #required_providers {
  #  aws    = "~> 1.11"
  #}

  backend "s3" {
    bucket = "theboardcompany-terraform"
    key    = "staging/ops/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "${var.aws_region}"

  # see above ^ https://github.com/hashicorp/terraform/issues/16835
  version = "= 1.19"
}

provider "template" {
  version = "~> 1.0"
}

# TODO: copy private key to S3 bucket
# TODO: check if private key is downloaded added to ssh agent
# resource "aws_key_pair" "deployer" {
#   key_name   = "theboardcompany-${var.environment}-key"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
# }

resource "aws_acm_certificate" "cert" {
  domain_name               = "${var.base_domain}"
  subject_alternative_names = ["*.${var.base_domain}"]
  validation_method         = "DNS"

  tags {
    Name = "ops"
  }
}

resource "aws_route53_zone" "zone" {
  name = "${var.base_domain}."

  # private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.zone.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

data "aws_elb_service_account" "main" {}
