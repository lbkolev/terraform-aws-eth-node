## <p align="center">terraform-aws-eth-node</p>
### <p align="center">Spin up an ETH client on AWS</p>

- The deployment takes no more than two minutes
- The module takes care of the:
  - EC2's configuration
  - creation & management of the volumes that'll hold the chains' data
  - mounting of the volumes
  - the installation & configuration of the specified ethereum node(s) 
  - EC2's security group

- Full examples can be found in the [examples](./examples/) directory.
> :warning: Be mindful with the security group's configuration. All the examples are simplified to allow all external traffic, which in most cases environments shouldn't happen.

## Example with both Besu & Nimbus client
```hcl
module "nodes" {
  source = "../../"

  name      = "besu-nimbus-mainnet"
  subnet_id = "/subnet-id/"

  ec2 = {
    instance_type               = "m4.xlarge"
    associate_public_ip_address = true
  }

  security_group = [
    {
      type        = "egress"
      from        = 0
      to          = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from        = 22
      to          = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from        = 8545
      to          = 8545
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from        = 8546
      to          = 8546
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  clients = [
    {
      name        = "besu"
      package_url = "https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/23.7.2/besu-23.7.2.tar.gz"
      cmd         = "besu --data-path=/besu"

      create_ebs = true
      ebs = {
        device_name = "xvdb"
        type        = "gp3"
        size        = 1000 // GB
        mountpoint  = "/besu"
      }
    },
    {
      name        = "nimbus"
      package_url = "https://github.com/status-im/nimbus-eth2/releases/download/v23.8.0/nimbus-eth2_Linux_amd64_23.8.0_d014d0a5.tar.gz"
      cmd         = "nimbus --data-dir=/nimbus"

      create_ebs = true
      ebs = {
        device_name = "xvdc"
        type        = "gp3"
        size        = 1000 // GB
        mountpoint  = "/nimbus"
      }
    }
  ]
}
```

## License
MIT Licensed. See [LICENSE](./LICENSE) for full details.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | The base AMI to use for the EC2 | <pre>object({<br>    name = string<br>  })</pre> | <pre>{<br>  "name": "debian-12-amd64-20230711-1438"<br>}</pre> | no |
| <a name="input_clients"></a> [clients](#input\_clients) | The ETH clients to deploy on the EC2 | <pre>list(<br>    object({<br>      name        = string<br>      package_url = string<br>      cmd         = string<br><br>      ebs = optional(object({<br>        device_name = string<br>        mountpoint  = string<br><br>        // Required if we're attaching an external EBS, rather than creation one here<br>        attach_external_ebs = optional(bool)<br>        external_volume_id  = optional(string)<br><br>        // Required if we're creating an EBS, rather than attaching an external one<br>        ebs_name = optional(string)<br>        type     = optional(string)<br>        size     = optional(number)<br>      }))<br>  }))</pre> | n/a | yes |
| <a name="input_ec2"></a> [ec2](#input\_ec2) | The EC2 configuration | <pre>object({<br>    type                        = optional(string)<br>    associate_public_ip_address = bool<br>    key_name                    = string<br>    security_group_ids          = optional(list(string)) // optional external SGs; ones created outside of this module.<br>    disable_api_stop            = optional(bool)<br>    disable_api_termination     = optional(bool)<br>    ebs_optimized               = optional(bool)<br>    get_password_data           = optional(bool)<br>    hibernation                 = optional(bool)<br>    key_name                    = optional(string)<br>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The generic name to apply across the different resources | `string` | n/a | yes |
| <a name="input_security_group"></a> [security\_group](#input\_security\_group) | The security group rules to apply to the EC2 | <pre>list(object({<br>    type        = string<br>    description = optional(string)<br>    from        = number<br>    to          = number<br>    protocol    = string<br>    cidr_blocks = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The subnet to deploy the EC2 in. Defaults to the first subnet returned by the data resource | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ebs"></a> [ebs](#output\_ebs) | EBS volumes created for the client(s) |
| <a name="output_ebs_attachment"></a> [ebs\_attachment](#output\_ebs\_attachment) | EBS volume attachment(s) created for the client(s) |
| <a name="output_ec2"></a> [ec2](#output\_ec2) | EC2 instance created for the client(s) |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | Security group created for the client(s) |
<!-- END_TF_DOCS -->
