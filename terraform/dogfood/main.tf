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

provider "aws" {
  region = "us-east-1"
  alias  = "global"
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

## Delegation Set
resource "aws_route53_delegation_set" "dogfood" {
  reference_name = "${var.alias}"
}

## Zones
resource "aws_route53_zone" "dogfood" {
  name              = "${var.domain}."
  tags              = "${merge(var.tags, map("Name", "${var.name}-zone"))}"
  delegation_set_id = "${aws_route53_delegation_set.dogfood.id}"
}

## Records
# Start-of-Authority
resource "aws_route53_record" "soa" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "SOA"
  ttl     = "${var.dns-ttl}"

  # MNAME: AWS NS
  # RNAME: hostmaster@ domain
  # SERIAL: 1
  # REFRESH: TTL variable
  # RETRY: TTL variable
  # EXPIRE: TTL variable * 1000
  # TTL/Minimum: TTL variable
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

##
## Email
##

## SMTP Delivery
resource aws_route53_record "mx" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "MX"
  ttl     = "${var.dns-ttl}"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com."]
}

## Routing
resource "aws_ses_receipt_rule_set" "dogfood" {
  rule_set_name = "${var.region}"
}

resource "aws_ses_active_receipt_rule_set" "dogfood" {
  rule_set_name = "${aws_ses_receipt_rule_set.dogfood.rule_set_name}"
}

## Rules
# WorkMail
resource "aws_ses_receipt_rule" "workmail" {
  rule_set_name = "${aws_ses_receipt_rule_set.dogfood.rule_set_name}"
  name          = "${var.alias}-workmail"
  recipients    = ["${var.domain}"]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Require"

  workmail_action {
    organization_arn = "arn:aws:workmail:${var.region}:${var.workmail_arn}"
    position         = "1"
  }
}

## Sender Policy Framework
resource aws_route53_record "spf" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "TXT"
  ttl     = "${var.dns-ttl}"
  records = ["v=spf1 include:amazonses.com -all"]
}

## Exchange/IMAP Autodiscovery
resource aws_route53_record "autodiscover" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "autodiscover.${var.domain}"
  type    = "CNAME"
  ttl     = "${var.dns-ttl}"
  records = ["autodiscover.mail.${var.region}.awsapps.com."]
}

## Simple Email Service(SES) identity verification
resource "aws_ses_domain_identity" "dogfood" {
  domain = "${var.domain}"
}

resource "aws_ses_domain_dkim" "dogfood" {
  domain = "${var.domain}"
}

resource "aws_route53_record" "ses-token" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "${var.dns-ttl}"
  records = ["${aws_ses_domain_identity.dogfood.verification_token}"]
}

resource "aws_route53_record" "ses-dkim" {
  zone_id = "${aws_route53_zone.dogfood.id}"

  # TODO: Why does length() fail here?
  count   = "3"
  name    = "${element(aws_ses_domain_dkim.dogfood.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "${var.dns-ttl}"
  records = ["${element(aws_ses_domain_dkim.dogfood.dkim_tokens, count.index)}.dkim.amazonses.com"]
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

##
## Web
##

# Bucket
resource "aws_s3_bucket" "website" {
  bucket = "${var.domain}"
  acl    = "public"
  tags   = "${merge(var.tags, map("Name", "${var.name}-website"))}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
    {
        "Sid": "PublicReadForGetBucketObjects",
        "Effect": "Allow",
        "Principal": {
            "AWS": "*"
         },
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::${var.domain}/*"
    }]
}
EOF

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "Version Archive"
    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "website-blog-redirect" {
  bucket           = "${aws_s3_bucket.website.bucket}"
  key              = "blog"
  content          = "null"
  website_redirect = "https://itvends.blog"
}

resource "aws_s3_bucket_object" "website-vend" {
  bucket           = "${aws_s3_bucket.website.bucket}"
  key              = "vend"
  content          = "null"
  website_redirect = "https://itvends.com/vend.php"
}

# SSL Certificate
resource "aws_acm_certificate" "website" {
  provider                  = "aws.global"
  domain_name               = "${var.domain}"
  subject_alternative_names = ["www.${var.domain}"]
  validation_method         = "DNS"
  tags                      = "${merge(var.tags, map("Name", "${var.name}-certificate"))}"
}

resource "aws_route53_record" "website-certifcate-root" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  ttl     = "${var.dns-ttl}"
  name    = "${aws_acm_certificate.website.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.website.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.website.domain_validation_options.0.resource_record_value}"]
}

resource "aws_route53_record" "website-certificate-www" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  ttl     = "${var.dns-ttl}"
  name    = "${aws_acm_certificate.website.domain_validation_options.1.resource_record_name}"
  type    = "${aws_acm_certificate.website.domain_validation_options.1.resource_record_type}"
  records = ["${aws_acm_certificate.website.domain_validation_options.1.resource_record_value}"]
}

# Cloudfront Distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  is_ipv6_enabled     = true

  aliases = ["${var.domain}", "www.${var.domain}"]
  tags    = "${merge(var.tags, map("Name", "${var.name}-cloudfront"))}"

  origin {
    origin_id   = "${var.alias}_website_origin"
    domain_name = "${aws_s3_bucket.website.website_endpoint}"

    # S3 Website backend is HTTP-only
    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1"]   # Required, but unused
    }
  }

  default_cache_behavior {
    min_ttl                = "0"
    default_ttl            = "${var.dns-ttl}"
    max_ttl                = "${var.dns-ttl * 1000}"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.alias}_website_origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${aws_acm_certificate.website.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  custom_error_response {
    error_caching_min_ttl = "${var.dns-ttl}"
    error_code            = 404
    response_code         = 200
    response_page_path    = "/error.html"
  }
}

# DNS Records
resource "aws_route53_record" "website-root-v4" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.website.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.website.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website-root-v6" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "${var.domain}"
  type    = "AAAA"

  alias {
    name                   = "${aws_cloudfront_distribution.website.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.website.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website-www-v4" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.website.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.website.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website-www-v6" {
  zone_id = "${aws_route53_zone.dogfood.id}"
  name    = "www.${var.domain}"
  type    = "AAAA"

  alias {
    name                   = "${aws_cloudfront_distribution.website.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.website.hosted_zone_id}"
    evaluate_target_health = false
  }
}
