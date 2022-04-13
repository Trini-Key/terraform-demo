# AWS Region and Availablility Zone
variable "region" {
  default = "us-east-1"
}

variable "availability_zone_1" {
  default = "us-east-1a"
}

variable "availability_zone_2" {
  default = "us-east-1b"
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
  default = "10.180.101.0/24"
}

variable "private_subnet_cidr_1" {
  default = "10.180.102.0/24"
}

variable "private_subnet_cidr_2" {
  default = "10.180.103.0/24"
}

variable "ec2_ami" {
  default = "ami-081a15e0483786bd1"
}