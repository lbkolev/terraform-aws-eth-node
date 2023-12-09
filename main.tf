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


resource "aws_iam_role" "this" {
  name = var.name
  /*
   * Required for SSM Access
   */
  assume_role_policy  = data.aws_iam_policy_document.policy_document.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
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


resource "aws_launch_template" "this" {
  depends_on = [aws_security_group.this]

  name                    = var.name
  image_id                = data.aws_ami.this.id
  vpc_security_group_ids  = var.compute.security_group_ids == null ? [aws_security_group.this[0].id] : concat(var.compute.security_group_ids, [aws_security_group.this[0].id])
  instance_type           = var.autoscaling.instance_type
  ebs_optimized           = try(var.compute.ebs_optimized, null)
  key_name                = try(var.compute.key_name, null)
  disable_api_stop        = try(var.compute.disable_api_stop, null)
  disable_api_termination = try(var.compute.disable_api_termination, null)

  user_data = templatefile("${path.module}/templates/init.sh.tftpl", {
    CLIENTS = var.clients
  })

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  placement {
    availability_zone = data.aws_subnet.this.availability_zone
  }

  network_interfaces {
    associate_public_ip_address = var.compute.associate_public_ip_address
  }


  tags = {
    Name        = var.name
    Description = "Launch Template for ${var.name}'s EC2 instance(s)"
  }
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

//resource "aws_instance" "this" {
//  depends_on = [aws_security_group.this]
//
//  ami                    = data.aws_ami.this.id
//  instance_type          = var.compute.type == null ? "t2.micro" : var.compute.type
//  subnet_id              = var.subnet_id
//  vpc_security_group_ids = var.compute.security_group_ids == null ? [aws_security_group.this[0].id] : concat(var.compute.security_group_ids, [aws_security_group.this[0].id])
//
//  availability_zone           = data.aws_subnet.this.availability_zone
//  associate_public_ip_address = try(var.compute.associate_public_ip_address, null)
//
//  disable_api_stop        = try(var.compute.disable_api_stop, null)
//  disable_api_termination = try(var.compute.disable_api_termination, null)
//  ebs_optimized           = try(var.compute.ebs_optimized, null)
//
//  get_password_data = try(var.compute.get_password_data, null)
//  hibernation       = try(var.compute.hibernation, null)
//  key_name          = try(var.compute.key_name, null)
//
//  user_data = templatefile("${path.module}/templates/init.sh.tftpl", {
//    CLIENTS = var.clients
//  })
//
//  lifecycle {
//    ignore_changes = [
//      ebs_block_device,
//      associate_public_ip_address
//    ]
//  }
//
//  tags = {
//    Name = var.name
//  }
//}

resource "aws_volume_attachment" "this" {
  for_each   = { for index, client in var.clients : client.name => client.ebs if client.ebs != null && contains(["pending", "running"], var.compute.state) }
  depends_on = [aws_instance.this]

  device_name = each.value.device_name
  volume_id   = each.value.external_volume_id == null ? aws_ebs_volume.this[each.key].id : each.value.external_volume_id
  instance_id = aws_instance.this.id
}

resource "aws_autoscaling_group" "this" {
  name     = var.name
  min_size = 1
  max_size = 1

  vpc_zone_identifier   = [var.subnet_id]
  max_instance_lifetime = var.autoscaling.instance_lifetime
  protect_from_scale_in = true

  launch_template {
    id = aws_launch_template.this.id
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = "true"
  }
}
