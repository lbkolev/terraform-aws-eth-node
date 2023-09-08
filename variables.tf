variable "name" {
  type        = string
  description = "The generic name to apply across the different resources created in AWS"
}

variable "subnet_id" {
  type        = string
  description = "The subnet to deploy the EC2 in. Defaults to the first subnet returned by the data resource"
}

variable "security_group" {
  type = list(object({
    type        = string
    description = optional(string)
    from        = number
    to          = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "The security group rules to apply to the EC2"
  default     = []
}

variable "ami" {
  type = object({
    name = string
  })
  description = "The base AMI to use for the EC2"
  default = {
    name = "debian-12-amd64-20230711-1438",
  }
}

variable "ec2" {
  type = object({
    type                        = optional(string, "t2.micro")
    state                       = optional(string, "running")
    associate_public_ip_address = bool
    security_group_ids          = optional(list(string)) # external SGs;
    disable_api_stop            = optional(bool)
    disable_api_termination     = optional(bool)
    ebs_optimized               = optional(bool)
    get_password_data           = optional(bool)
    hibernation                 = optional(bool)
    key_name                    = optional(string)
  })
  description = "The EC2 configuration"
  default = {
    type                        = "t2.micro",
    state                       = "running",
    associate_public_ip_address = true
  }

  validation {
    condition     = can(regex("^((a1|c1|c3|c4|c5|c5a|c5ad|c5d|c5n|c6a|c6g|c6gd|c6gn|c6i|c6id|c7g|cc2|d2|d3|d3en|dl1|f1|g2|g3|g3s|g4ad|g4dn|g5|g5g|h1|i2|i3|i3en|i4i|im4gn|inf1|is4gen|m1|m2|m3|m4|m5|m5a|m5ad|m5d|m5dn|m5n|m5zn|m6a|m6g|m6gd|m6i|m6id|mac1|mac2|p2|p3|p3dn|p4d|r3|r4|r5|r5a|r5ad|r5b|r5d|r5dn|r5n|r6a|r6g|r6gd|r6i|r6id|t1|t2|t3|t3a|t4g|trn1|u-12tb1|u-3tb1|u-6tb1|u-9tb1|vt1|x1|x1e|x2gd|x2idn|x2iedn|x2iezn|z1d)\\.(10xlarge|112xlarge|12xlarge|16xlarge|18xlarge|24xlarge|2xlarge|32xlarge|3xlarge|48xlarge|4xlarge|56xlarge|6xlarge|8xlarge|9xlarge|large|medium|metal|micro|nano|small|xlarge))$", var.ec2.type))
    error_message = "value must be a valid EC2 instance type"
  }

  validation {
    condition     = contains(["running", "stopped"], var.ec2.state)
    error_message = "Invalid EC2 state. Valid states are: running, stopped"
  }
}

variable "clients" {
  type = list(
    object({
      name        = string # name of the ethereum client
      package_url = string # link to the url of the binary to download
      cmd         = string # the startup command of the client

      ebs = optional(object({
        device_name = string
        mountpoint  = string

        # Required if we're attaching an external EBS, rather than creation one here
        attach_external_ebs = optional(bool)
        external_volume_id  = optional(string)

        # Required if we're creating an EBS, rather than attaching an external one
        ebs_name = optional(string)
        type     = optional(string)
        size     = optional(number)
      }))
  }))
  description = "The nodes to deploy on the EC2"

  validation {
    condition     = length(var.clients) > 0
    error_message = "You must provide at least one client"
  }

  validation {
    condition = length([
      for c in var.clients :
      true if contains(["geth", "nethermind", "besu", "erigon", "reth", "lighthouse", "nimbus", "prysm", "teku"], c.name)
    ]) == length(var.clients)
    error_message = "Invalid client name. Valid names are: geth, nethermind, besu, erigon, reth, lighthouse, nimbus, prysm, teku"
  }
}
