# 
resource "aws_iam_role" "s3_lambda" {
  name = "${var.app_name}-s3-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_lambda" {
  name = "${var.app_name}-s3-lambda-role-policy"
  role = "${aws_iam_role.s3_lambda.id}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "s3:*",
            "Effect": "Allow",
            "Resource": "${aws_s3_bucket.alb_logs.arn}",
            "Sid": ""
        }
    ]
}
EOF
}

module "alb_logcollector" {
  source     = "../../../modules/aws/lambdas/alb-logcollector"
  name       = "${var.app_name}"
  env        = "${var.environment}"
  bucket_arn = "${aws_s3_bucket.alb_logs.arn}"
}
