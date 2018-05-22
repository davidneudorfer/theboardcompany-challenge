data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${var.app_name}-ecs-policy"
  path        = "/"
  description = "registry_ecs_policy"
  policy      = "${data.aws_iam_policy_document.instance_role.json}"
}

resource "aws_iam_policy_attachment" "registry_ecs_service" {
  name       = "${var.app_name}-ecs-service"
  roles      = ["${aws_iam_role.registry_ecs_service.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_role" "registry_ecs_service" {
  name = "${var.app_name}-ec2-service"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}"
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.app_name}"

  container_definitions = <<DEFINITIONS
[
  {
    "cpu": ${var.cpu_unit},
    "essential": true,
    "image": "${var.image}",
    "memory": ${var.memory},
    "name": "${var.app_name}",
    "portMappings": [
      {
        "containerPort": ${var.container_port}
      }
    ]
  }
]
DEFINITIONS
}

resource "aws_ecs_service" "main" {
  name            = "${var.app_name}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "${var.service_count}"
  iam_role        = "${aws_iam_role.registry_ecs_service.arn}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.main.id}"
    container_name   = "${var.app_name}"
    container_port   = "${var.container_port}"
  }
}
