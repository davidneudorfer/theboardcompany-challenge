# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/1.31.0
module "theboardcompany_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.31.0"

  name = "tbc-${var.environment}.vpc"
  cidr = "${var.aws_cidr}"

  azs             = "${var.aws_azs}"
  private_subnets = "${var.aws_private_subnets}"
  public_subnets  = "${var.aws_public_subnets}"

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

module "bastion" {
  source = "../../../modules/aws/bastion-host"

  bucket_name = "tbc-bastion-${var.environment}-logs"

  region = "${var.aws_region}"

  vpc_id = "${module.theboardcompany_vpc.vpc_id}"

  is_lb_private     = false
  create_dns_record = true

  bastion_host_key_pair = "${data.terraform_remote_state.base.aws_key_name}"
  hosted_zone_name      = "${data.terraform_remote_state.base.zone_id}"
  bastion_record_name   = "bastion-${var.environment}.${data.terraform_remote_state.base.base_domain}"

  elb_subnets                = "${module.theboardcompany_vpc.private_subnets}"
  auto_scaling_group_subnets = "${module.theboardcompany_vpc.public_subnets}"

  tags {
    Name        = "tbc-${var.environment}-bastion-host"
    description = "my_bastion_description"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

# TODO: add CloudWatch AutoScaling Events
module "app" {
  source = "../../../modules/aws/ecs-spotfleet-alb"

  vpc         = "${module.theboardcompany_vpc.vpc_id}"
  region      = "${var.aws_region}"
  environment = "${var.environment}"

  bastion_host_security_group = "${module.bastion.bastion_host_security_group}"
  private_subnets             = "${module.theboardcompany_vpc.private_subnets}"
  public_subnets              = "${module.theboardcompany_vpc.public_subnets}"
  spot_prices                 = ["${var.app_spot_price}", "${var.app_spot_price}"]

  key_name            = "${data.terraform_remote_state.base.aws_key_name}"
  app_name            = "${var.app_subdomain}-${var.environment}"
  alb_log_bucket_name = "${var.app_subdomain}-${var.environment}-alb-logs"

  fqdn         = "${var.app_subdomain}.${data.terraform_remote_state.base.base_domain}"
  route53_zone = "${data.terraform_remote_state.base.zone_id}"
  acm          = "${data.terraform_remote_state.base.certificate_arn}"

  image          = "${var.app_image}"
  service_count  = "${var.app_service_count}"
  instance_type  = "${var.app_instance_size}"
  instance_count = "${var.app_instance_count}"
  volume_size    = "${var.app_root_volume_size}"
}
