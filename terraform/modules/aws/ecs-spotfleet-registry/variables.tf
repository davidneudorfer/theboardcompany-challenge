// Required

variable "environment" {
  default = "ops"
}

variable "vpc_id" {
  description = "VPC id for ECS cluster"
}

variable "acm" {}
variable "route53_zone" {}

variable "fqdn" {}

variable "bastion_host_security_group" {
  default = "Security Group from the 'bastion' module"
}

variable "public_subnets" {
  type        = "list"
  description = "List of subnet ids for Application Load Balancer, please choose 2 subnets"
}

variable "private_subnets" {
  type        = "list"
  description = "List of subnet ids for ECS cluster, please choose 2 subnets"
}

variable "key_name" {
  description = "Name of key pair for SSH login to ECS cluster instances"
}

variable "region" {
  description = "Region for ECS cluster"
  default     = "us-west-2"
}

// Customize for container options

variable "app_name" {
  description = "Your application name"
  default     = "demo-app"
}

variable "image" {
  description = "Your docker image name, default it ECS PHP Simple App"
  default     = "wata727/ecs-demo-php-simple-app:latest"
}

variable "container_port" {
  description = "Port number exposed by container"
  default     = 5000
}

variable "service_count" {
  description = "Number of containers"
  default     = 3
}

variable "cpu_unit" {
  description = "Number of cpu units for container"
  default     = 128
}

variable "memory" {
  description = "Number of memory for container"
  default     = 128
}

// Customize for spot fleet options

variable "spot_prices" {
  description = "Bid amount to spot fleet"
  type        = "list"
  default     = ["0.03", "0.03"]
}

variable "strategy" {
  description = "Instance placement strategy name"
  default     = "diversified"
}

variable "instance_count" {
  description = "Number of instances"
  default     = 3
}

variable "instance_type" {
  description = "Instance type launched by spot fleet"
  default     = "m3.medium"
}

variable "volume_size" {
  description = "Root volume size"
  default     = 16
}

variable "app_port" {
  description = "Port number of application"
  default     = 80
}

variable "valid_until" {
  description = "limit of spot fleet"
  default     = "2020-12-15T00:00:00Z"
}
