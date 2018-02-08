# vim: set filetype=terraform
# terraform/dogfood/main.tf
# itvends/cloud
#
# Main Module Structure
#

# Terraform requirements
terraform {
  # Built against
  required_version = ">= 0.11.2"
}

##
## Networking
##

# VPC
resource "aws_vpc" "this" {
  cidr_block                       = "${var.cidr}"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true
  tags                             = "${var.tags}"
}

# DHCP Options
resource "aws_vpc_dhcp_options" "this" {
  domain_name         = "${var.domain}"
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
  tags                = "${var.tags}"
}
