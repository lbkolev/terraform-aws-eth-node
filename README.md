## <p align="center">terraform-aws-eth-node</p>
### <p align="center">Spin up Ethereum execution/consensus clients on AWS.</p>

- The deployment takes no more than a minute
- All clients are managed through systemd

- The module takes care of the:
  - EC2's setup, configuration & lifecycle
  - Creation & management of the volumes that'll hold the data

- Full examples can be found in the [examples](./examples/) directory.
> :warning: Be mindful with the security group's configuration. All the examples are simplified to allow all external traffic, which in most cases isn't recommended.

## License
MIT Licensed. See [LICENSE](./LICENSE) for full details.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.30.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.attach_ebs_volume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | The base AMI to use for the EC2 | <pre>object({<br>    name = string<br>  })</pre> | <pre>{<br>  "name": "debian-12-amd64-20230711-1438"<br>}</pre> | no |
| <a name="input_clients"></a> [clients](#input\_clients) | The nodes to deploy on the EC2 | <pre>list(<br>    object({<br>      name        = string # name of the ethereum client<br>      package_url = string # link to the url of the binary to download<br>      cmd         = string # the startup command of the client<br><br>      ebs = optional(object({<br>        device_name = string<br>        mountpoint  = string<br>        type        = string<br>        size        = number<br>      }))<br>  }))</pre> | n/a | yes |
| <a name="input_compute"></a> [compute](#input\_compute) | The EC2 configuration | <pre>object({<br>    type                        = optional(string, "t2.micro")<br>    state                       = optional(string, "running")<br>    associate_public_ip_address = bool<br>    security_group_ids          = optional(list(string)) # external SGs;<br>    ebs_optimized               = optional(bool)<br>    disable_api_stop            = optional(bool)<br>    disable_api_termination     = optional(bool)<br>    key_name                    = optional(string)<br>    max_instance_lifetime       = optional(number)<br>  })</pre> | <pre>{<br>  "associate_public_ip_address": true,<br>  "state": "running",<br>  "type": "t2.micro"<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The generic name to apply across the different resources created in AWS | `string` | n/a | yes |
| <a name="input_security_group"></a> [security\_group](#input\_security\_group) | The security group rules to apply to the EC2 | <pre>list(object({<br>    type        = string<br>    description = optional(string)<br>    from        = number<br>    to          = number<br>    protocol    = string<br>    cidr_blocks = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The subnet to deploy the EC2 in. Defaults to the first subnet returned by the data resource | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_compute"></a> [compute](#output\_compute) | Compute created for the client(s) |
| <a name="output_ebs"></a> [ebs](#output\_ebs) | EBS volumes created for the client(s) |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | Security group created for the client(s) |
<!-- END_TF_DOCS -->
