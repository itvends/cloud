# vim: set filetype=terraform
# terraform/sokkeli/variables.tf
# itvends/cloud
#
# Input Variables
#

variable "meta-prefix" {
  description = "Resource Name Prefix"
  default     = "sokkeli"
}

variable "meta-tags" {
  description = "Unique resource identifiers"
  default     = {}
}

variable "admin-username" {
  description = "Administrator User"
  default     = "admin"
}

variable "admin-pubkey" {
  description = "SSH RSA Public Key"

  # REQUIRED!
}

variable "axle-location" {
  description = "Region code"
  default     = "eastus"
}

variable "axle-cidr" {
  description = "CIDR Subnet Prefix"
  default     = "10.10.0.0/18"
}

variable "hub-a-address" {
  description = "VPN Hub A"
  default     = "1.2.3.4"
}

variable "hub-a-subnets" {
  description = "VPN Sunets A"
  default     = ["10.11.0.0/16"]
}
variable "hub-a-secret" {
	description = "IPsec Key"
	default = "1234567890"
}

variable "hub-b-address" {
  description = "VPN Hub B"
  default     = "5.6.7.8"
}

variable "hub-b-subnets" {
  description = "VPN Subnets B"
  default     = ["10.12.0.0/16"]
}
variable "hub-b-secret" {
	description = "IPsec Key"
	default = "1234567890"
}

variable "spoke-location" {
  description = "Region code list"
  default     = ["eastus"]
}

variable "spoke-cidr" {
  description = "CIDR Subnet Prefix"
  default     = "10.10.64.0/18"
}
