# vim: set filetype=terraform
# terraform/itvends.tf
# itvends/cloud
#
# Base Infrastructure Provisioning
#

provider "aws" {
  region  = "us-west-2"
  version = "~> 1.7"
}

module "dogfood" {
  source = "./dogfood"

  tags = {
    Name   = "dogfood"
    Tenant = "ItVends"
  }
}
