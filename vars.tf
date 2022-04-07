# AWS Region and Availablility Zone
variable "region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1e"
}

# VPC configuration
variable "vpc_cidr_block" {
  default = "10.180.0.0/16"
}

variable "vpc_instance_tenancy" {
  default = "default"
}

variable "vpc_name" {
  default = "TF DEMO"
}
variable "public_subnet_cidr" {
  default = "10.180.10.0/24"
}

variable "private_subnet_cidr_1" {
  default = "10.180.50.0/24"
}

variable "private_subnet_cidr_2" {
  default = "10.180.60.0/24"
}

variable "ec2_ami" {
  default = "ami-081a15e0483786bd1"
}