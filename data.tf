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

data "aws_iam_policy_document" "policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "attach_ebs_volume_policy" {
  version = "2012-10-17"

  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}
