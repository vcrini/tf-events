config {
  module     = true
  force      = false
}

plugin "aws" {
  enabled = true
  deep_check = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}
