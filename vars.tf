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

variable "availability_zone_3" {
  default = "us-east-1c"
}

variable "availability_zone_4" {
  default = "us-east-1d"
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
variable "public_subnet_cidr_1" {
  default = "10.180.101.0/24"
}

variable "public_subnet_cidr_2" {
  default = "10.180.102.0/24"
}

variable "private_subnet_cidr_1" {
  default = "10.180.2.0/24"
}

variable "private_subnet_cidr_2" {
  default = "10.180.3.0/24"
}

variable "ec2_ami" {
  default = "ami-081a15e0483786bd1"
}

variable "ssh_port" {
  type = number
  description = "The port the server will use for SSH"
  default = 22
}

variable "web_port" {
  type = number
  description = "The port the server will use for HTTP Requests"
  default = 80
}