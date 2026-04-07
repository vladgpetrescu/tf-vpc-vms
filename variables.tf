################################################################################
# VPC / General
################################################################################

variable "name" {
  description = "Name to be used on all the resources as an identifier"
  type        = string
}

variable "tags" {
  description = "A map of additional key-value tags to set on all resources"
  type        = map(string)
  default     = {}
}

variable "create_private_resources" {
  description = "Enables the creation of the private resources such as private subnet, private VM, NAT Gateway, etc - to be used in testing"
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  description = "Path to the public key (.pub) to be used when creating the VMs - you must present the private key when connecting"
  type        = string
  default     = "~/.ssh/aws.pub"
}

variable "ssh_key_name" {
  description = "The name to be used for the AWS key pair - must be unique on the AWS region used"
  type        = string
  default     = null
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}


################################################################################
# Publiс subnet
################################################################################

variable "public_subnet_cidr" {
  description = "IPv4 CIDRs to be used for the public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_ingress_cidr" {
  description = "IPv4 CIDR to allow on the public VM ingress"
  type        = string
}


################################################################################
# Private subnet
################################################################################

variable "private_subnet_cidr" {
  description = "IPv4 CIDRs to be used for the public subnet"
  type        = string
  default     = "10.0.32.0/24"
}

################################################################################
# VMs
################################################################################

variable "instance_type" {
  description = "The OS type to be used for the VMs: linux or windows"
  type        = string
  default     = "linux"
}
