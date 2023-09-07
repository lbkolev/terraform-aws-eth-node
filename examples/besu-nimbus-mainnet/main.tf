data "aws_subnets" "this" {
  tags = {
    Name = "main-public-*"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "besu-nimbus-mainnet-manager"
  create_private_key = true
}

module "nodes" {
  source = "../../"

  name      = "besu-nimbus-mainnet"
  subnet_id = data.aws_subnets.this.ids[0]

  ec2 = {
    instance_type               = "m4.xlarge"
    associate_public_ip_address = true
    key_name                    = module.key_pair.key_pair_name
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
        size        = 1000 # GB
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
        size        = 1000 # GB
        mountpoint  = "/nimbus"
      }
    }
  ]
}
