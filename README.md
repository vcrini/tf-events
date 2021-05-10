## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.15.0, < 0.16.0 |
| aws | ~> 3.9.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.9.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_dev | environment variable needed to Lambda for deploying in dev cluster | `string` | n/a | yes |
| cluster\_prod | environment variable needed to Lambda for deploying in prod cluster | `string` | n/a | yes |
| prefix | some to differentiate, usually project 'fdh' or 'dpl' | `string` | n/a | yes |
| retention\_in\_days | how many days wait before deleting logs | `number` | `30` | no |
| role\_arn | assumed to create infrastructure in enviroment where .hcl is ran | `string` | n/a | yes |
| role\_arn\_lambda\_name | role used by lambda | `string` | n/a | yes |
| tag | tag to be added | `map(any)` | `{}` | no |
| test\_role\_arn | role needed from lambda to assume in order to access to test environment from production | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| role\_arn | default role |
| role\_arn\_lambda | default role |

