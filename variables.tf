data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "cluster_dev" {
  description = "environment variable needed to Lambda for deploying in dev cluster"
  type        = string
}
variable "cluster_prod" {
  description = "environment variable needed to Lambda for deploying in prod cluster"
  type        = string
}
variable "prefix" {
  description = "some to differentiate, usually project 'fdh' or 'dpl'"
  type        = string
}
variable "retention_in_days" {
  default     = 30
  description = "how many days wait before deleting logs"
  type        = number
}
variable "role_arn" {
  description = "assumed to create infrastructure in enviroment where .hcl is ran"
  type        = string
}
variable "role_arn_lambda_name" {
  description = "role used by lambda"
  type        = string
}
variable "test_role_arn" {
  description = "role needed from lambda to assume in order to access to test environment from production"
  type        = string
}
variable "tag" {
  default = {
  }
  description = "tag to be added"
  type        = map(any)
}
locals {
  region          = data.aws_region.current.name
  account_id      = data.aws_caller_identity.current.account_id
  role_prefix     = "arn:aws:iam::${local.account_id}:role/"
  role_arn_lambda = "${local.role_prefix}${var.role_arn_lambda_name}"
}
