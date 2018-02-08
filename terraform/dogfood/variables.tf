# vim: set filetype=terraform
# terraform/dogfood/variables.tf
# itvends/cloud
#
# Input Variables
#

variable "tags" {
  description = "Unique resource identifiers"

  default = {
    Name = "dogfood"
  }
}

variable "cidr" {
  description = "IP block for the VPC"
  default     = "10.0.0.0/16"
}

variable "domain" {
  description = "DNS domain name"
  default     = ""
}
