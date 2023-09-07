variable "name" {
  type        = string
  description = "The generic name to apply across the different resources"
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
    type                        = optional(string)
    associate_public_ip_address = bool
    key_name                    = string
    security_group_ids          = optional(list(string)) # optional external SGs; ones created outside of this module.
    disable_api_stop            = optional(bool)
    disable_api_termination     = optional(bool)
    ebs_optimized               = optional(bool)
    get_password_data           = optional(bool)
    hibernation                 = optional(bool)
    key_name                    = optional(string)
  })
  description = "The EC2 configuration"
}

variable "clients" {
  type = list(
    object({
      name        = string
      package_url = string
      cmd         = string

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
  description = "The ETH clients to deploy on the EC2"

  validation {
    condition     = alltrue([for client in var.clients : true if contains(["geth", "nethermind", "besu", "erigon", "reth", "lighthouse", "nimbus", "prysm", "teku"], client.name)])
    error_message = "Invalid client name. Valid names are: geth, nethermind, besu, erigon, reth, lighthouse, nimbus, prysm, teku"
  }
}
