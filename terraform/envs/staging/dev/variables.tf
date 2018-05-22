//
// Base
//

variable "aws_key_name" {
  default = "theboardcompany"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "environment" {
  description = "eg., 'ops'"
}

variable "aws_cidr" {
  default = "172.31.0.0/16"
}

variable "aws_azs" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "aws_private_subnets" {
  default = ["172.31.1.0/24", "172.31.2.0/24", "172.31.3.0/24"]
}

variable "aws_public_subnets" {
  default = ["172.31.101.0/24", "172.31.102.0/24", "172.31.103.0/24"]
}

variable "key_pair" {
  default = "theboardcompany"
}

variable "base_domain" {
  default = "tbc.vasandani.me"
}

//
// App
//

variable "app_spot_price" {
  default = "0.007"
}

variable "app_instance_size" {
  default = "m3.medium"
}

variable "app_subdomain" {
  default = "challenge"
}

variable "app_service_count" {
  default = 1
}

variable "app_instance_count" {
  default = 1
}

variable "app_root_volume_size" {
  default = 10
}

variable "app_image" {
  default = "tutum/hello-world:latest"
}
