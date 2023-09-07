data "aws_subnets" "this" {
  tags = {
    Name = "main-public-*"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "geth-teku-mainnet-manager"
  create_private_key = true
}

module "nodes" {
  source = "../../"

  name      = "geth-teku-mainnet"
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
    }
  ]

  clients = [
    {
      name        = "geth"
      package_url = "https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.12.2-bed84606.tar.gz"
      cmd         = "geth --datadir=/geth --http --http.addr=0.0.0.0 --http.port=8545 --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.origins '*' --ws.api eth,net,web3,debug,txpool --authrpc.addr=127.0.0.1 --authrpc.port 8551 --authrpc.jwtsecret=/geth/jwt.hex --bootnodes enode://9246d00bc8fd1742e5ad2428b80fc4dc45d786283e05ef6edbd9002cbc335d40998444732fbe921cb88e1d2c73d1b1de53bae6a2237996e9bfe14f871baf7066@18.168.182.86:30303,enode://ec66ddcf1a974950bd4c782789a7e04f8aa7110a72569b6e65fcd51e937e74eed303b1ea734e4d19cfaec9fbff9b6ee65bf31dcb50ba79acce9dd63a6aca61c7@52.14.151.177:30303"

      create_ebs = true
      ebs = {
        device_name = "xvdb"
        type        = "gp3"
        size        = 1000
        mountpoint  = "/geth"
      }
    },
    {
      name        = "teku"
      package_url = "https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/23.9.0/teku-23.9.0.tar.gz"
      cmd         = "teku --data-beacon-path=/teku --data-path=/teku --ee-endpoint=http://localhost:8551"

      create_ebs = true
      ebs = {
        device_name = "xvdc"
        type        = "gp2"
        size        = 1000
        mountpoint  = "/teku"
      }
    }
  ]
}
