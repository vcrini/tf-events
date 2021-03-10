provider "aws" {
  assume_role {
    role_arn = var.role_arn
  }
}
provider "aws" {
  alias = "prod"
  assume_role {
    role_arn = var.role_arn2
  }
}

