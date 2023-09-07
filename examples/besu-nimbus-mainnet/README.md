## besu-nimbus-mainnet

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.15.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_key_pair"></a> [key\_pair](#module\_key\_pair) | terraform-aws-modules/key-pair/aws | n/a |
| <a name="module_nodes"></a> [nodes](#module\_nodes) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_subnets.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_pair"></a> [key\_pair](#output\_key\_pair) | n/a |
| <a name="output_nodes"></a> [nodes](#output\_nodes) | n/a |
<!-- END_TF_DOCS -->
