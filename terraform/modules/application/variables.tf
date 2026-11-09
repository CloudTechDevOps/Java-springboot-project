variable "project_name" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "instance_type" { type = string }
variable "key_name" {
  type     = string
  nullable = true
}
variable "db_address" { type = string }
variable "db_name" { type = string }
variable "db_username_param" { type = string }
variable "db_password_param" { type = string }
variable "db_username_param_arn" { type = string }
variable "db_password_param_arn" { type = string }
