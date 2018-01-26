#
# terraform/itvends.tf
# itvends/cloud
#
# Base Infrastructure Provisioning
#

provider "aws" {
	region = "us-west-2"
	version = "~> 1.7"
}

## Networking
# VPC Network
resource "aws_vpc" "Oregon" {
	cidr_block = "198.19.32.0/20"
	assign_generated_ipv6_cidr_block = "true"
}
resource "aws_subnet" "Oregon-A" {
	vpc_id = "${aws_vpc.Oregon.id}"
	cidr_block = "${cidrsubnet(aws_vpc.Oregon.cidr_block, 4, 0)}"
	ipv6_cidr_block = "${cidrsubnet(aws_vpc.Oregon.ipv6_cidr_block, 8, 0)}"
	availability_zone = "us-west-2a"
	map_public_ip_on_launch = "true"
	assign_ipv6_address_on_creation = "true"
}
resource "aws_subnet" "Oregon-B" {
	vpc_id = "${aws_vpc.Oregon.id}"
	cidr_block = "${cidrsubnet(aws_vpc.Oregon.cidr_block, 4, 1)}"
	ipv6_cidr_block = "${cidrsubnet(aws_vpc.Oregon.ipv6_cidr_block, 8, 1)}"
	availability_zone = "us-west-2b"
	map_public_ip_on_launch = "true"
	assign_ipv6_address_on_creation = "true"
}
resource "aws_subnet" "Oregon-C" {
	vpc_id = "${aws_vpc.Oregon.id}"
	cidr_block = "${cidrsubnet(aws_vpc.Oregon.cidr_block, 4, 2)}"
	ipv6_cidr_block = "${cidrsubnet(aws_vpc.Oregon.ipv6_cidr_block, 8, 2)}"
	availability_zone = "us-west-2c"
	map_public_ip_on_launch = "true"
	assign_ipv6_address_on_creation = "true"
}
# Internet Gateway
resource "aws_internet_gateway" "Oregon" {
	vpc_id = "${aws_vpc.Oregon.id}"
}
resource "aws_egress_only_internet_gateway" "Oregon" {
	vpc_id = "${aws_vpc.Oregon.id}"
}

# Routing table
resource "aws_route_table" "Oregon" {
	vpc_id = "${aws_vpc.Oregon.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.Oregon.id}"
	}
	route {
		ipv6_cidr_block = "::/0"
		egress_only_gateway_id = "${aws_egress_only_internet_gateway.Oregon.id}"
	}
}
resource "aws_main_route_table_association" "Oregon" {
	vpc_id = "${aws_vpc.Oregon.id}"
	route_table_id = "${aws_route_table.Oregon.id}"
}

## Security
# SSH Key
resource "aws_key_pair" "eugene-jeeves" {
	key_name = "eugene@jeeves"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLSSEbMSYvD8/SLCbp0tiiXOqWnWC/2boaCGbqpmpDtwaD8uigF/AvCmoMQ01CGUfVbZMAjNi8B4AQDry1oz8iILit/9fOsdLBPQhrpmofiDjGk72IePIvEVB463syQWNrckJEMt3nePL+N2VrJ0vdU0oawpndemUFBLIqTyOYpYaW+VWvA0JCcq9LJVpWvs2ckeSEjSuDh8aaoZVgDGiv6jtgZaCNxFccopJmfOvnRWhzvu8ejiwVwnFHSkM5aTar5WnCu/16HTBbXUmSdBv8ZNXcpq/3FYbTL65mNsuVh3EkJ9WK2VXbYR6YE8mI7oAPvFbmmkFPGoLTv8+M/ZssLmACfNkM3480FjSdL7+dvhnCBjAEXSr9iP3FCDSifFckb3DIOcXbjzr8NNZkNHAc+7n31YYmjeGa0eNxrhTO6HtpbYJZ5j/0OdvDTcqZuTiGjRWv+8xvHdVSZWOgiAkh/raTha4W8busjStWeRu6vwuJFhpH3liMhqyKp9u+aJb3wktj31fgG14c+6PnbIloRb5ISKbLD5dX1cgrp+n7vzO4X2Pb+QFPK6e9/nTYgq4URPQfHWhUvJTZapR5kyVYxgWYgd6w5sQFApvIRzbCBozxb8lnWev4Hik8zVxyYwrc2OTRzyAjZ7D9NCvgC8XKyR8kqP++rGu7OV17VU3snQ== eugene@jeeves"
}


# Bastion host

resource "aws_instance" "bastion" {
	# FreeBSD 11.1-STABLE-amd64-2018-01-25
	ami = "ami-343c834c"
	instance_type = "t2.micro"
	key_name = "eugene@jeeves"
	subnet_id = "${aws_subnet.Oregon-A.id}"
	provisioner "local-exec" {
		command = "echo ${aws_instance.bastion.public_ip} > ip_address.txt"
	}
}
