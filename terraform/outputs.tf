# vim: set filetype=terraform
# terraform/itvends.tf
# itvends/cloud
#
# Infrastructure information
#

# NS records which must be set at registrar
output "delegation_set" {
  value = ["${module.dogfood.delegation_set}"]
}

output "hosts" {
  value = "${module.dogfood.hosts}"
}
