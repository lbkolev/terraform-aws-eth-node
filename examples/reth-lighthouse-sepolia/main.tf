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

  compute = {
    instance_type               = "c4.xlarge"
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
