## <p align="center">terraform-aws-eth-node</p>
### <p align="center">Spin up ETH clients. On AWS. In a minute.</p>

- The deployment takes no more than a minute
- The default OS is `debian12`
- All clients are managed through systemd

- The module takes care of the:
  - EC2's setup, configuration & lifecycle
  - Creation & management of the volumes that'll hold the chains' data

- Full examples can be found in the [examples](./examples/) directory.
> :warning: Be mindful with the security group's configuration. All the examples are simplified to allow all external traffic, which in most cases isn't recommended.

## Example with Reth & Lighthouse running sepolia
```hcl
module "nodes" {
  source = "../../"

  name      = "[reth-lighthouse]-sepolia"
  subnet_id = data.aws_subnets.this.ids[0]

  ec2 = {
    instance_type               = "c4.xlarge"
    associate_public_ip_address = true # required if you ever intend to access the nodes from outside the vpc
    key_name                    = module.key_pair.key_pair_name # # required to access the ec2
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
    }
  ]

  clients = [
    {
      name        = "reth"
      package_url = "https://github.com/paradigmxyz/reth/releases/download/v0.1.0-alpha.8/reth-v0.1.0-alpha.8-x86_64-unknown-linux-gnu.tar.gz"
      cmd         = "reth node --chain=sepolia --full --datadir=/reth --authrpc.addr=127.0.0.1 --authrpc.port 8551 --authrpc.jwtsecret=/root/jwt.hex --http --http.addr=0.0.0.0 --http.port=8545 --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.origins '*' --ws.api eth,net,web3,debug,txpool --bootnodes enode://9246d00bc8fd1742e5ad2428b80fc4dc45d786283e05ef6edbd9002cbc335d40998444732fbe921cb88e1d2c73d1b1de53bae6a2237996e9bfe14f871baf7066@18.168.182.86:30303,enode://ec66ddcf1a974950bd4c782789a7e04f8aa7110a72569b6e65fcd51e937e74eed303b1ea734e4d19cfaec9fbff9b6ee65bf31dcb50ba79acce9dd63a6aca61c7@52.14.151.177:30303"

      ebs = {
        device_name = "xvdb"
        type        = "gp2"
        size        = 100 # GB
        mountpoint  = "/reth"
      }
    },
    {
      name        = "lighthouse"
      package_url = "https://github.com/sigp/lighthouse/releases/download/v4.4.1/lighthouse-v4.4.1-x86_64-unknown-linux-gnu-portable.tar.gz"
      cmd         = "lighthouse bn --network=sepolia --datadir=/lighthouse --execution-jwt=/root/jwt.hex --execution-endpoint=http://127.0.0.1:8551 --disable-deposit-contract-sync --checkpoint-sync-url https://sepolia.checkpoint-sync.ethpandaops.io"

      ebs = {
        device_name = "xvdc"
        type        = "gp2"
        size        = 2 # GB
        mountpoint  = "/lighthouse"
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
