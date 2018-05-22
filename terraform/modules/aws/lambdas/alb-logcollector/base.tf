variable "env" {}

variable "name" {
  default = "node_example"
}

variable "bucket_arn" {}

//
// Policy
//

#
# create policy and role for basic lambda with vpc access.
# http://misguided.io/2016/02/24/terraform-a-default-lamba-role/

resource "aws_iam_policy" "main" {
  name        = "${var.name}"
  path        = "/"
  description = "push logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "Stmt1444812758000",
    "Effect": "Allow",
    "Action": [
        "s3:Get*",
        "s3:List*"
    ],
    "Resource": [
        "*"
    ]
  },
  {
    "Action": [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Effect": "Allow",
    "Resource": "arn:aws:logs:*:*:*"
  }]
}

EOF
}

//
// Roles
//

resource "aws_iam_role" "main" {
  name = "${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
EOF
}

//
// Attach policy to roles
//

resource "aws_iam_policy_attachment" "main" {
  name       = "${var.name}"
  roles      = ["${aws_iam_role.main.name}"]
  policy_arn = "${aws_iam_policy.main.arn}"
}

//
// create lambda function
//

resource "aws_lambda_function" "alb_logcollector" {
  filename         = "${path.module}/build.zip"
  function_name    = "${var.name}"
  role             = "${aws_iam_role.main.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("${path.module}/build.zip"))}"
  runtime          = "nodejs4.3"
  timeout          = "300"
}

//
// Lambda Permissions
//

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.alb_logcollector.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${var.bucket_arn}"
}

//
// Ouputs
//

output "arn" {
  value = "${aws_lambda_function.alb_logcollector.arn}"
}
