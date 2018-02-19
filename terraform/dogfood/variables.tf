# vim: set filetype=terraform
# terraform/dogfood/variables.tf
# itvends/cloud
#
# Input Variables
#

variable "tags" {
  description = "Unique resource identifiers"

  default = {
    Tenant = "dogfood"
  }
}

variable "name" {
  description = "Unique Name identifier"
  default     = "dogfood"
}

variable "cidr" {
  description = "IP block for the VPC"
  default     = "10.0.0.0/16"
}

variable "domain" {
  description = "DNS domain name"
  default     = ""
}

variable "alias" {
  description = "Alias for NetBIOS and Single Sign-On"
  default     = ""
}

variable "dns-ttl" {
  description = "Time-To-Live for static record caching"
  default     = "1000"
}

variable "admin" {
  description = "Administrative username"
  default     = "dogfood"
}

variable "password" {
  description = "Initial Admin password"
  default     = "Ch4ngeM3!"
}

variable "pubkey" {
  description = "SSH Public Key for admin"
}

variable "ami" {
  description = "Amazon Machine Image for dogfood host"
  default     = "ami-d728afaf"                          # FreeBSD 11.1
}

variable "region" {
  description = "AWS Region for instantiation"
  default     = "us-east-1"
}
variable "workmail_arn" {
	description = "ARN of WorkMail instance"
}
