# vim: set filetype=terraform
# terraform/itvends.tf
# itvends/cloud
#
# Base Infrastructure Provisioning
#

module "dogfood" {
  source = "./dogfood"
  region = "us-west-2"
  name   = "It Vends"

  tags = {
    Tenant = "ItVends"
  }

  domain       = "itvends.cloud"
  alias        = "itvends"
  workmail_arn = "767827555133:organization/m-d07a978964544577b1c6103b63824f5b"

  admin  = "eugene"
  pubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLSSEbMSYvD8/SLCbp0tiiXOqWnWC/2boaCGbqpmpDtwaD8uigF/AvCmoMQ01CGUfVbZMAjNi8B4AQDry1oz8iILit/9fOsdLBPQhrpmofiDjGk72IePIvEVB463syQWNrckJEMt3nePL+N2VrJ0vdU0oawpndemUFBLIqTyOYpYaW+VWvA0JCcq9LJVpWvs2ckeSEjSuDh8aaoZVgDGiv6jtgZaCNxFccopJmfOvnRWhzvu8ejiwVwnFHSkM5aTar5WnCu/16HTBbXUmSdBv8ZNXcpq/3FYbTL65mNsuVh3EkJ9WK2VXbYR6YE8mI7oAPvFbmmkFPGoLTv8+M/ZssLmACfNkM3480FjSdL7+dvhnCBjAEXSr9iP3FCDSifFckb3DIOcXbjzr8NNZkNHAc+7n31YYmjeGa0eNxrhTO6HtpbYJZ5j/0OdvDTcqZuTiGjRWv+8xvHdVSZWOgiAkh/raTha4W8busjStWeRu6vwuJFhpH3liMhqyKp9u+aJb3wktj31fgG14c+6PnbIloRb5ISKbLD5dX1cgrp+n7vzO4X2Pb+QFPK6e9/nTYgq4URPQfHWhUvJTZapR5kyVYxgWYgd6w5sQFApvIRzbCBozxb8lnWev4Hik8zVxyYwrc2OTRzyAjZ7D9NCvgC8XKyR8kqP++rGu7OV17VU3snQ=="
}
