variable "project_name" {
  type        = string
  default     = "java-springboot-project"
  description = "Prefix for resources created by this project."
}

variable "environment" {
  type        = string
  description = "Deployment environment. Use a separate Terraform workspace for each value."

  validation {
    condition     = contains(["main", "dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: main, dev, test, prod."
  }
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for this deployment."
}

variable "azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Two availability zones used for the VPC and RDS subnet group."

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two availability zones for the RDS subnet group."
  }
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type. Availability and Free Tier eligibility vary by region and account."
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "RDS instance class. Availability and Free Tier eligibility vary by region and account."
}

variable "key_name" {
  type        = string
  default     = null
  description = "Optional EC2 key pair name. SSH is not opened by default; use Systems Manager Session Manager."
  nullable    = true
}

variable "db_username" {
  type        = string
  description = "RDS master username."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "RDS master password. Terraform state will contain this secret; protect the state file."
  sensitive   = true
}

variable "db_name" {
  type        = string
  default     = "datastore"
  description = "Application database name."
}
