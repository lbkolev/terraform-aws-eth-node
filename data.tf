data "aws_subnet" "this" {
  id = var.subnet_id
}

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
