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
## AWS 
##
provider "aws" {
  region  = "${var.region}"
  version = "~> 1.7"
}

data "aws_availability_zones" "available" {
  state = "available"
}

##
## Networking
##

# VPC
resource "aws_vpc" "dogfood" {
  cidr_block                       = "${var.cidr}"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true
  tags                             = "${merge(var.tags, map("Name", "${var.name}-VPC"))}"
}

# DHCP Options
resource "aws_vpc_dhcp_options" "dogfood" {
  domain_name         = "${var.domain}"
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
  tags                = "${merge(var.tags, map("Name", "${var.name}-DHCP"))}"
}

# Gateway
resource "aws_internet_gateway" "dogfood" {
  vpc_id = "${aws_vpc.dogfood.id}"
  tags   = "${merge(var.tags, map("Name", "${var.name}-gateway"))}"
}

# Subnets
resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.dogfood.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "${cidrsubnet(aws_vpc.dogfood.cidr_block, 8, 0)}"
  ipv6_cidr_block   = "${cidrsubnet(aws_vpc.dogfood.ipv6_cidr_block, 8, 0)}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  tags                            = "${merge(var.tags, map("Name", "${var.name}-subnet-public"))}"
}

resource "aws_subnet" "private" {
  tags              = "${merge(var.tags, map("Name", "${var.name}-subnet-private"))}"
  vpc_id            = "${aws_vpc.dogfood.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block        = "${cidrsubnet(aws_vpc.dogfood.cidr_block, 8, 1)}"
  ipv6_cidr_block   = "${cidrsubnet(aws_vpc.dogfood.ipv6_cidr_block, 8, 1)}"

  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true
}

# Routing table
resource aws_route_table "dogfood" {
  tags   = "${merge(var.tags, map("Name", "${var.name}-routes-public"))}"
  vpc_id = "${aws_vpc.dogfood.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dogfood.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.dogfood.id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.dogfood.id}"
}

## Network ACLs
# Default
resource "aws_default_network_acl" "default" {
  tags                   = "${merge(var.tags, map("Name", "${var.name}-acl-default"))}"
  default_network_acl_id = "${aws_vpc.dogfood.default_network_acl_id}"

  # Inbound
  ingress {
    rule_no    = "1"
    protocol   = "-1"
    from_port  = "0"
    to_port    = "0"
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  ingress {
    rule_no         = "2"
    protocol        = "-1"
    from_port       = "0"
    to_port         = "0"
    ipv6_cidr_block = "::/0"
    action          = "deny"
  }

  # Outbound
  egress {
    rule_no    = "1"
    protocol   = "-1"
    from_port  = "0"
    to_port    = "0"
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  egress {
    rule_no         = "2"
    protocol        = "-1"
    from_port       = "0"
    to_port         = "0"
    ipv6_cidr_block = "::/0"
    action          = "deny"
  }
}

# Public
resource "aws_network_acl" "public" {
  vpc_id     = "${aws_vpc.dogfood.id}"
  tags       = "${merge(var.tags, map("Name", "${var.name}-acl-public"))}"
  subnet_ids = ["${aws_subnet.public.id}"]

  # Inbound
  ingress {
    rule_no    = "1"
    protocol   = "-1"
    from_port  = "0"
    to_port    = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    rule_no         = "2"
    protocol        = "-1"
    from_port       = "0"
    to_port         = "0"
    ipv6_cidr_block = "::/0"
    action          = "allow"
  }

  # Outbound
  egress {
    rule_no    = "1"
    protocol   = "-1"
    from_port  = "0"
    to_port    = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no         = "2"
    protocol        = "-1"
    from_port       = "0"
    to_port         = "0"
    ipv6_cidr_block = "::/0"
    action          = "allow"
  }
}

# Private
resource "aws_network_acl" "private" {
  vpc_id     = "${aws_vpc.dogfood.id}"
  tags       = "${merge(var.tags, map("Name", "${var.name}-acl-private"))}"
  subnet_ids = ["${aws_subnet.private.id}"]

  # Inbound
  ingress {
    rule_no    = "1"
    protocol   = "-1"
    from_port  = "0"
    to_port    = "0"
    cidr_block = "${aws_subnet.public.cidr_block}"
    action     = "allow"
  }

  ingress {
    rule_no         = "2"
    protocol        = "-1"
    from_port       = "0"
    to_port         = "0"
    ipv6_cidr_block = "${aws_subnet.public.ipv6_cidr_block}"
    action          = "allow"
  }

  # Outbound
  egress {
    rule_no    = "1"
    protocol   = "-1"
    from_port  = "0"
    to_port    = "0"
    cidr_block = "${aws_subnet.public.cidr_block}"
    action     = "allow"
  }

  egress {
    rule_no         = "2"
    protocol        = "-1"
    from_port       = "0"
    to_port         = "0"
    ipv6_cidr_block = "${aws_subnet.public.ipv6_cidr_block}"
    action          = "allow"
  }
}

## Security Groups
resource "aws_security_group" "dogfood" {
  name   = "dogfood"
  vpc_id = "${aws_vpc.dogfood.id}"
  tags   = "${merge(var.tags, map("Name", "${var.name}-sg-dogfood"))}"

  ingress {
    description      = "Inbound"
    protocol         = "-1"
    from_port        = "0"
    to_port          = "0"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Outbound"
    protocol         = "-1"
    from_port        = "0"
    to_port          = "0"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

##
## Hosts
##

## Key Pair
resource "aws_key_pair" "dogfood" {
  key_name_prefix = "${var.admin}"
  public_key      = "${var.pubkey}"
}

## Bastion
resource "aws_instance" "dogfood" {
  ami                    = "${var.ami}"
  instance_type          = "t2.micro"
  tags                   = "${merge(var.tags, map("Name", "${var.name}-bastion"))}"
  volume_tags            = "${merge(var.tags, map("Name", "${var.name}-bastion-system"))}"
  key_name               = "${aws_key_pair.dogfood.key_name}"
  subnet_id              = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.dogfood.id}"]
}

##
## DNS
##

## Zone
resource "aws_route53_zone" "dogfood" {
  name = "${var.domain}."
  tags = "${merge(var.tags, map("Name", "${var.name}-zone"))}"
}

## Records
# Start-of-Authority
resource "aws_route53_record" "soa" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "SOA"
  ttl     = "${var.dns-ttl}"
  records = ["${aws_route53_zone.dogfood.name_servers.0}. hostmaster.${var.domain}. 1 ${var.dns-ttl} ${var.dns-ttl} ${var.dns-ttl * 1000} ${var.dns-ttl}"]
}

# Nameservers
resource "aws_route53_record" "ns" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "NS"
  ttl     = "${var.dns-ttl * 1000}"
  records = ["${formatlist("%s.", aws_route53_zone.dogfood.name_servers)}"]
}

# Email
resource aws_route53_record "mx" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "MX"
  ttl     = "${var.dns-ttl}"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com."]
}
resource aws_route53_record "spf" {
	zone_id = "${aws_route53_zone.dogfood.id}"
	name		= "${var.domain}"
	type		= "TXT"
	ttl			= "${var.dns-ttl}"
	records	= ["v=spf1 include:amazonses.com -all"]
}

# Exchange/IMAP Autodiscovery
resource aws_route53_record "autodiscover" {
	zone_id = "${aws_route53_zone.dogfood.id}"
	name		= "autodiscover.${var.domain}"
	type		= "CNAME"
	ttl			= "${var.dns-ttl}"
	records	= ["autodiscover.mail.${var.region}.awsapps.com."]
}
##
## Directory Service
##

resource "aws_directory_service_directory" "dogfood" {
  name       = "${var.domain}"
  password   = "${var.password}"
  type       = "SimpleAD"
  size       = "Small"
  tags       = "${merge(var.tags, map("Name", "${var.name}-directory"))}"
  enable_sso = true
  alias      = "${var.alias}"
  short_name = "${var.alias}"

  vpc_settings {
    vpc_id     = "${aws_vpc.dogfood.id}"
    subnet_ids = ["${aws_subnet.public.id}", "${aws_subnet.private.id}"]
  }
}

## AWS Management Console
# Manually managed, no Terraform state

## WorkDocs
# Manually managed, no Terraform state

## WorkMail
# Manually managed, some components in Terraform.

## WorkSpaces
# Manually managed, no Terraform state

