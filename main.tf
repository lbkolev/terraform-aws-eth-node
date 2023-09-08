resource "aws_security_group" "this" {
  count = var.security_group == [] ? 0 : 1

  name   = var.name
  vpc_id = data.aws_subnet.this.vpc_id

  dynamic "ingress" {
    for_each = { for index, sg in var.security_group : index => sg if sg.type == "ingress" }

    content {
      description = try(ingress.value.description, null)
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = { for index, sg in var.security_group : index => sg if sg.type == "egress" }

    content {
      description = try(egress.value.description, null)
      from_port   = egress.value.from
      to_port     = egress.value.to
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_ebs_volume" "this" {
  for_each = { for index, client in var.clients : client.name => client.ebs if client.ebs.attach_external_ebs != true }

  availability_zone = data.aws_subnet.this.availability_zone
  size              = try(each.value.size, null)
  type              = try(each.value.type, null)
  iops              = try(each.value.iops, null)
  throughput        = try(each.value.throughput, null)

  encrypted            = try(each.value.encrypted, null)
  final_snapshot       = try(each.value.final_snapshot, null)
  multi_attach_enabled = try(each.value.multi_attach_enabled, null)
  snapshot_id          = try(each.value.snapshot_id, null)
  kms_key_id           = try(each.value.kms_key_id, null)

  tags = {
    Name = each.key
  }
}

resource "aws_instance" "this" {
  depends_on = [aws_security_group.this, aws_ebs_volume.this]

  ami                    = data.aws_ami.this.id
  instance_type          = var.ec2.type == null ? "t2.micro" : var.ec2.type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.ec2.security_group_ids == null ? [aws_security_group.this[0].id] : concat(var.ec2.security_group_ids, [aws_security_group.this[0].id])

  availability_zone           = data.aws_subnet.this.availability_zone
  associate_public_ip_address = try(var.ec2.associate_public_ip_address, null)

  disable_api_stop        = try(var.ec2.disable_api_stop, null)
  disable_api_termination = try(var.ec2.disable_api_termination, null)
  ebs_optimized           = try(var.ec2.ebs_optimized, null)

  get_password_data = try(var.ec2.get_password_data, null)
  hibernation       = try(var.ec2.hibernation, null)
  key_name          = try(var.ec2.key_name, null)

  user_data = templatefile("${path.module}/templates/init.sh.tftpl", {
    CLIENTS = var.clients
  })

  lifecycle {
    ignore_changes = [
      ebs_block_device
    ]
  }

  tags = {
    Name = var.name
  }
}

resource "aws_volume_attachment" "this" {
  for_each = { for index, client in var.clients : client.name => client.ebs if client.ebs != null }

  device_name = each.value.device_name
  volume_id   = each.value.external_volume_id == null ? aws_ebs_volume.this[each.key].id : each.value.external_volume_id
  instance_id = aws_instance.this.id
}

resource "aws_ec2_instance_state" "this" {
  count = var.ec2.state == null ? 0 : 1

  instance_id = aws_instance.this.id
  state       = var.ec2.state
}
