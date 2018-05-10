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

variable "ami-bastion" {
  description = "Amazon Machine Image for bastion host"
  default     = "ami-fd1d9485" # FreeBSD 11.1-STABLE-amd64-2018-02-26
}
variable "ami-master" {
  description = "Amazon Machine Image for Salt Master"
  default     = "ami-fd1d9485" # FreeBSD 11.1-STABLE-amd64-2018-02-26
}
variable "ami-portal" {
	description = "Amazon Machine Image for Portal host"
	default = "ami-74800e0c" # Windows_Server-2016-English-Full-Base-2018.02.23
}
variable "ami-controller" {
	description = "Amazon Machine Image for Domain Controller"
	default = "ami-48820c30" # Windows_Server-2016-English-Core-Base-2018.02.23
}

variable "region" {
  description = "AWS Region for instantiation"
  default     = "us-east-1" # us-east-1, us-west-2, or eu-west-1 ONLY! Services availability. 
}
variable "workmail_arn" {
	description = "ARN of WorkMail instance"
}
