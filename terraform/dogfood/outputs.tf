# vim: set filetype=terraform
# terraform/dogfood/outputs.tf
# itvends/cloud
#
# Module Outputs
#

output "delegation_set" {
  value = ["${aws_route53_delegation_set.dogfood.name_servers}"]
}
