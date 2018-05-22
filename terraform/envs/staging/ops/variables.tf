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

variable "aws_key_name" {
  default = "theboardcompany"
}

variable "base_domain" {
  default = "tbc.vasandani.me"
}

//
// Registry
//

variable "registry_spot_price" {
  default = "0.007"
}

variable "registry_instance_size" {
  default = "m3.medium"
}

variable "registry_subdomain" {
  default = "docker"
}
