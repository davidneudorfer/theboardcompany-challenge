terraform {
  required_version = "> 0.11"

  #FUTURE (https://github.com/hashicorp/terraform/issues/16835)
  #required_providers {
  #  aws    = "~> 1.11"
  #}

  backend "s3" {
    bucket = "theboardcompany-terraform"
    key    = "staging/dev/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "${var.aws_region}"

  # see above ^ https://github.com/hashicorp/terraform/issues/16835
  version = "~> 1.19"
}

provider "template" {
  version = "~> 1.0"
}

data "aws_acm_certificate" "main" {
  domain      = "${var.base_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "main" {
  name         = "${var.base_domain}."
  private_zone = false
}
