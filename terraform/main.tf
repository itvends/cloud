#
# terraform/itvends.tf
# itvends/cloud
#
# Base Infrastructure Provisioning
#
variable "allocation" {
  type    = "string"
  default = "10.0.0.0/16"
}

provider "aws" {
  region  = "us-west-2"
  version = "~> 1.7"
}

data "aws_availability_zones" "zones" {}

## Networking
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "It Vends"
  cidr   = "${var.allocation}"
  azs    = "${data.aws_availability_zones.zones.names}"

  public_subnets = ["${cidrsubnet(var.allocation, 8, 0)}",
    "${cidrsubnet(var.allocation, 8, 1)}",
    "${cidrsubnet(var.allocation, 8, 2)}",
  ]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "itvends.cloud"
  dhcp_options_domain_name_servers = ["8.8.8.8,8.8.4.4"]

  tags = {
    Name   = "Oregon"
    Tenant = "ItVends"
  }
}

## Security
# SSH Key
resource "aws_key_pair" "eugene-jeeves" {
  key_name   = "eugene@jeeves"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLSSEbMSYvD8/SLCbp0tiiXOqWnWC/2boaCGbqpmpDtwaD8uigF/AvCmoMQ01CGUfVbZMAjNi8B4AQDry1oz8iILit/9fOsdLBPQhrpmofiDjGk72IePIvEVB463syQWNrckJEMt3nePL+N2VrJ0vdU0oawpndemUFBLIqTyOYpYaW+VWvA0JCcq9LJVpWvs2ckeSEjSuDh8aaoZVgDGiv6jtgZaCNxFccopJmfOvnRWhzvu8ejiwVwnFHSkM5aTar5WnCu/16HTBbXUmSdBv8ZNXcpq/3FYbTL65mNsuVh3EkJ9WK2VXbYR6YE8mI7oAPvFbmmkFPGoLTv8+M/ZssLmACfNkM3480FjSdL7+dvhnCBjAEXSr9iP3FCDSifFckb3DIOcXbjzr8NNZkNHAc+7n31YYmjeGa0eNxrhTO6HtpbYJZ5j/0OdvDTcqZuTiGjRWv+8xvHdVSZWOgiAkh/raTha4W8busjStWeRu6vwuJFhpH3liMhqyKp9u+aJb3wktj31fgG14c+6PnbIloRb5ISKbLD5dX1cgrp+n7vzO4X2Pb+QFPK6e9/nTYgq4URPQfHWhUvJTZapR5kyVYxgWYgd6w5sQFApvIRzbCBozxb8lnWev4Hik8zVxyYwrc2OTRzyAjZ7D9NCvgC8XKyR8kqP++rGu7OV17VU3snQ== eugene@jeeves"
}

# Bastion host

resource "aws_instance" "bastion" {
  # FreeBSD 11.1-STABLE-amd64-2018-01-25
  ami           = "ami-343c834c"
  instance_type = "t2.micro"
  key_name      = "eugene@jeeves"
  subnet_id     = "${module.vpc.public_subnets[0]}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.bastion.public_ip} > ip_address.txt"
  }
}
