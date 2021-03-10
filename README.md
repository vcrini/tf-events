## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13.4 |
| aws | ~> 3.9.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.9.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| es\_alias | es alias  where storing ingestion | `string` | n/a | yes |
| es\_cluster | es cluster to whitelist for notifies | `string` | n/a | yes |
| es\_host | ES host used to ingest data | `string` | n/a | yes |
| es\_secret | ssm parameter to retrieve user password | `string` | n/a | yes |
| es\_user | user used to login to ES server | `string` | n/a | yes |
| retention\_in\_days | how many days wait before deleting logs | `number` | `30` | no |
| role\_arn | assumed to create infrastructure in enviroment where .hcl is ran | `string` | n/a | yes |
| role\_arn\_lambda\_name | role used by lambda | `string` | n/a | yes |
| tag | tag to be added | `map` | <pre>{<br>  "Project": "FactoryDataHub"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| role\_arn\_lambda | default role |
