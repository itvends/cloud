# vim: set filetype=terraform
# terraform/dogfood/outputs.tf
# itvends/cloud
#
# Module Outputs
#

output "delegation_set" {
  value = {
		id = "${aws_route53_delegation_set.dogfood.id}"
		servers = ["${aws_route53_delegation_set.dogfood.name_servers}"]
	}
}

output "hosts" {
  value = {
    bastion = {
      id   = "${aws_instance.bastion.id}"
      ipv4 = "${aws_instance.bastion.public_ip}"
      ipv6 = ["${aws_instance.bastion.ipv6_addresses}"]
    }

    #		master = {
    #			id = "${aws_instance.master.id}"
    #			ipv4 = "${aws_instance.master.public_ip}"
    #			ipv6 = ["${aws_instance.master.ipv6_addresses}"]
    #		}
    #		controller = {
    #			id = "${aws_instance.controller.id}"
    #			ipv4 = "${aws_instance.controller.public_ip}"
    #			ipv6 = ["${aws_instance.controller.ipv6_addresses}"]
    #		}
    #		portal = {
    #			id = "${aws_instance.portal.id}"
    #			ipv4 = "${aws_instance.portal.public_ip}"
    #			ipv6 = ["${aws_instance.portal.ipv6_addresses}"]
    #		}
  }
}
