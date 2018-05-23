//
// Base
//
variable "aws_region" {
  default = "us-west-2"
}

variable "environment" {
  description = "eg., 'ops'"
}

variable "aws_cidr" {
  default = "172.30.0.0/16"
}

variable "aws_azs" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "aws_private_subnets" {
  default = ["172.30.1.0/24", "172.30.2.0/24", "172.30.3.0/24"]
}

variable "aws_public_subnets" {
  default = ["172.30.101.0/24", "172.30.102.0/24", "172.30.103.0/24"]
}

//
// Registry
//
variable "registry_app_name" {
  default = "registry"
}

variable "registry_image" {
  default = "registry:latest"
}

variable "registry_spot_price" {
  default = "0.007"
}

variable "registry_instance_type" {
  default = "m3.medium"
}

variable "registry_subdomain" {
  default = "docker"
}

variable "registry_service_count" {
  default = 1
}

variable "registry_instance_count" {
  default = 1
}

variable "registry_volume_size" {
  default = 10
}
