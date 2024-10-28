variable "aws_region" {
  description = "The AWS region to deploy resources."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the web app."
  type        = string
  default     = "***"
}

variable "instance_type" {
  description = "The instance type to use for the EC2 instances."
  type        = string
  default     = "t2.small"
}

variable "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate for the domain name."
  type        = string
  default     = ""
}

variable "aws_key_pair_name" {
  type        = string
  description = "Name of the AWS key pair"
}

variable "initial_private_key_path" {
  type        = string
  description = "Path to the private key for the AWS key pair"
}
