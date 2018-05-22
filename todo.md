# TODO: add new env and data provider for global variables like dns and zone information
# TODO: peer vpc's so you only need one bastion instance
# TODO: add s3 lifecycle policy for ALB logs
# TODO: templatize lambda script
# TODO: setup locust.io on SpotFleet
# TODO: ensure all resource names are underscore _ vs -
# TODO: add CloudWatch Log "All 100 log records added to ES." to CloudWatch Metrics
# TODO: fork bastion module https://registry.terraform.io/modules/Guimove/bastion/aws/1.0.4

# FIXME: ssh though bastion network ALB fails to connect

# FUTURE: changes to launch_specification are ignored
# https://github.com/terraform-providers/terraform-provider-aws/issues/741

# FUTURE: launch_specification -> iam_instance_profile doesn't work. use iam_instance_profile_arn instead.
# https://github.com/terraform-providers/terraform-provider-aws/issues/4449