

URL: https://challenge.tbc.vasandani.me/
Bucket: challenge-dev-alb-logs
Log Collector: https://challenge-logcollector.herokuapp.com/log/view/theboardcompany

Modified [aws-sample/amazon-elasticsearch-lambda-samples](https://github.com/aws-samples/amazon-elasticsearch-lambda-samples/blob/master/src/s3_lambda_es.js) to extract gzip'd log files and push custom json to custom endpoint.

Run `make todo` to see all TODO, FIXME, and FUTURE tags. Most are inline with the code some 
```
# TODO: setup locust.io on SpotFleet
# TODO: ensure all resource names are underscore _ vs -
# TODO: add CloudWatch Log "All 100 log records added to ES." to CloudWatch Metrics
# TODO: add s3 lifecycle policy for ALB logs
# TODO: templatize lambda script
# TODO: peer vpc's so you only need one bastion instance

# FIXME: ssh though bastion network ALB fails to connect

# FUTURE: changes to launch_specification are ignored
# https://github.com/terraform-providers/terraform-provider-aws/issues/741

# FUTURE: launch_specification -> iam_instance_profile doesn't work. use iam_instance_profile_arn instead.
# https://github.com/terraform-providers/terraform-provider-aws/issues/4449
```