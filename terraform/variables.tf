variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition = contains([
      "us-west-2",
      "us-east-1", 
      "ap-southeast-1"
    ], var.aws_region)
    error_message = "Region must be one of: us-west-2, us-east-1, ap-southeast-1."
  }
}

variable "vscode_server_version" {
  description = "Version of code-server to install"
  type        = string
  default     = "4.91.1"
}

variable "internet_cidr_block" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_id" {
  description = "VPC ID to deploy resources (optional, uses default VPC if not specified)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID to deploy EC2 instance (optional, uses default subnet if not specified)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for code-server"
  type        = string
  default     = "t2.xlarge"
}

variable "origin_request_policy_id" {
  description = "CloudFront origin request policy ID"
  type        = string
  default     = "216adef6-5c7f-47e4-b989-5492eafa07d3"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "code-server"
  }
}
