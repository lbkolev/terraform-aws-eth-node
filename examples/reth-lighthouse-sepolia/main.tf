data "aws_subnets" "this" {
  tags = {
    Name = "main-public-*"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "reth-lightnouse-sepolia-manager"
  create_private_key = true
}

module "nodes" {
  source = "../../"

  name      = "reth-lighthouse-sepolia"
  subnet_id = data.aws_subnets.this.ids[0]

  ec2 = {
    instance_type               = "t2.micro"
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
    }
  ]

  clients = [
    {
      name        = "reth"
      package_url = "https://github.com/paradigmxyz/reth/releases/download/v0.1.0-alpha.8/reth-v0.1.0-alpha.8-x86_64-unknown-linux-gnu.tar.gz"
      cmd         = "reth node --chain=sepolia --full --datadir=/reth"

      create_ebs = true
      ebs = {
        device_name = "xvdb"
        type        = "gp2"
        size        = 100 # GB
        mountpoint  = "/reth"
      }
    },
    {
      name        = "lighthouse"
      package_url = "https://github.com/sigp/lighthouse/releases/download/v4.4.1/lighthouse-v4.4.1-x86_64-unknown-linux-gnu.tar.gz"
      cmd         = "lighthouse bn --network sepolia --datadir=/lighthouse --disable-deposit-contract-sync --checkpoint-sync-url https://sepolia.checkpoint-sync.ethpandaops.io"

      create_ebs = true
      ebs = {
        device_name = "xvdc"
        type        = "gp2"
        size        = 70 # GB
        mountpoint  = "/lighthouse"
      }
    }
  ]
}
