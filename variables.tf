variable "ssh_private_key" {
  description = "The private key for SSH connection to the instances"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}