data "aws_iam_policy_document" "ecs_instance" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "instance_policy" {
  name        = "${var.app_name}-ecs-instance-policy"
  path        = "/"
  description = "${var.app_name}-ecs-instance-policy"
  policy      = "${data.aws_iam_policy_document.ecs_instance.json}"
}

data "aws_iam_policy_document" "fleet_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeSubnets",
      "ec2:RequestSpotInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeInstanceStatus",
      "iam:PassRole",
    ]

    resources = ["*"]
    effect    = "Allow"
    actions   = ["elasticloadbalancing:RegisterInstancesWithLoadBalancer"]
    resources = ["arn:aws:elasticloadbalancing:*:*:loadbalancer/*"]
    effect    = "Allow"
    actions   = ["elasticloadbalancing:RegisterTargets"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "fleet_role" {
  name        = "${var.app_name}-fleet-policy"
  path        = "/"
  description = "${var.app_name}-fleet-policy"
  policy      = "${data.aws_iam_policy_document.fleet_policy.json}"
}

resource "aws_iam_policy_attachment" "ecs_instance" {
  name       = "${var.app_name}-ecs-instance"
  roles      = ["${aws_iam_role.ecs_instance.name}"]
  policy_arn = "${aws_iam_policy.instance_policy.arn}"
}

resource "aws_iam_role" "ecs_instance" {
  name = "${var.app_name}-ecs-instance"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.app_name}-ecs-instance"
  role = "${aws_iam_role.ecs_instance.name}"
}

resource "aws_security_group" "ecs_instance" {
  name        = "${var.app_name}-ecs-instance"
  description = "container security group for ${var.app_name}"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "TCP"
    security_groups = ["${aws_security_group.ecs_alb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_policy_attachment" "fleet" {
  name       = "${var.app_name}-fleet"
  roles      = ["${aws_iam_role.fleet.name}"]
  policy_arn = "${aws_iam_policy.fleet_role.arn}"
}

resource "aws_iam_role" "fleet" {
  name = "${var.app_name}-fleet"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "spotfleet.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

data "template_file" "user_data" {
  template = <<USER_DATA
#!/bin/bash
echo "ECS_CLUSTER=${var.app_name}" >> /etc/ecs/ecs.config
USER_DATA
}

resource "aws_spot_fleet_request" "main" {
  iam_fleet_role                      = "${aws_iam_role.fleet.arn}"
  spot_price                          = "${var.spot_prices[0]}"
  allocation_strategy                 = "${var.strategy}"
  target_capacity                     = "${var.instance_count}"
  terminate_instances_with_expiration = true
  valid_until                         = "${var.valid_until}"

  launch_specification {
    ami                      = "${data.aws_ami.ecs_ami.id}"
    instance_type            = "${var.instance_type}"
    spot_price               = "${var.spot_prices[0]}"
    subnet_id                = "${var.private_subnets[0]}"
    vpc_security_group_ids   = ["${aws_security_group.ecs_instance.id}", "${var.bastion_host_security_group}"]
    iam_instance_profile_arn = "${aws_iam_instance_profile.ecs.arn}"

    key_name = "${var.key_name}"

    root_block_device = {
      volume_type = "ssd"
      volume_size = "${var.volume_size}"
    }

    tags {
      Name        = "${var.app_name}"
      Environment = "${var.environment}"
      Terraform   = "true"
    }

    user_data = "${data.template_file.user_data.rendered}"
  }

  launch_specification {
    ami                      = "${data.aws_ami.ecs_ami.id}"
    instance_type            = "${var.instance_type}"
    spot_price               = "${var.spot_prices[1]}"
    subnet_id                = "${var.private_subnets[1]}"
    vpc_security_group_ids   = ["${aws_security_group.ecs_instance.id}", "${var.bastion_host_security_group}"]
    iam_instance_profile_arn = "${aws_iam_instance_profile.ecs.arn}"

    key_name = "${var.key_name}"

    root_block_device = {
      volume_type = "gp2"
      volume_size = "${var.volume_size}"
    }

    tags {
      Name        = "${var.app_name}"
      Environment = "${var.environment}"
      Terraform   = "true"
    }

    user_data = "${data.template_file.user_data.rendered}"
  }

  depends_on = ["aws_iam_policy_attachment.fleet"]
}
