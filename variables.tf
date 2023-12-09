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

variable "compute" {
  type = object({
    type                        = optional(string, "t2.micro")
    state                       = optional(string, "running")
    associate_public_ip_address = bool
    security_group_ids          = optional(list(string)) # external SGs;
    ebs_optimized               = optional(bool)
    disable_api_stop            = optional(bool)
    disable_api_termination     = optional(bool)
    key_name                    = optional(string)
    max_instance_lifetime       = optional(number)
  })
  description = "The EC2 configuration"
  default = {
    type                        = "t2.micro",
    state                       = "running",
    associate_public_ip_address = true
  }

  validation {
    condition     = contains(["running", "stopped"], var.compute.state)
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
        type        = string
        size        = number
      }))
  }))
  description = "The nodes to deploy on the EC2"

  validation {
    condition     = length(var.clients) > 0
    error_message = "You must provide at least one client"
  }
}
