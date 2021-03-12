data "aws_caller_identity" "current" {}
#variable "es_alias" {
#  description = "es alias  where storing ingestion"
#  type        = string
#}
#variable "es_cluster" {
#  description = "es cluster to whitelist for notifies"
#  type        = string
#}
#variable "es_host" {
#  description = "ES host used to ingest data"
#  type        = string
#}
#variable "es_secret" {
#  description = "ssm parameter to retrieve user password"
#  type        = string
#}
#variable "es_user" {
#  description = "user used to login to ES server"
#  type        = string
#}
variable "prefix" {
  description = "some to differentiate, usually project 'fdh' or 'dpl'"
  type = string
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

variable "tag" {
  default = {
  }
  description = "tag to be added"
  type        = map
}
locals {
  account_id      = data.aws_caller_identity.current.account_id
  role_prefix     = "arn:aws:iam::${local.account_id}:role/"
  role_arn_lambda = "${local.role_prefix}${var.role_arn_lambda_name}"
}
