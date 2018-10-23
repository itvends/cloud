# vim: set filetype=terraform
# terraform/sokkeli/main.tf
# itvends/cloud
#
# Main Module Structure
#

# Terraform requirements
terraform {
  # Built against
  required_version = "0.11.9"
}

##
## Azure
##

## 
provider "azurerm" {
  version = "~> 1.17"
}

## TODO: Access Key setup?

##
## Axle
##

resource "azurerm_resource_group" "axle" {
  name     = "${var.meta-prefix}-axle"
  location = "${var.axle-location}"
  tags     = "${var.meta-tags}"
}

resource "azurerm_virtual_network" "axle" {
  name                = "${var.meta-prefix}-axle"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  address_space = ["${cidrsubnet(var.axle-cidr, 4, 0)}"]
}

resource "azurerm_subnet" "axle" {
  name                = "${var.meta-prefix}-axle"
  resource_group_name = "${azurerm_resource_group.axle.name}"

  virtual_network_name = "${azurerm_virtual_network.axle.name}"
  address_prefix       = "${cidrsubnet(var.axle-cidr, 6, 0)}"
}

resource "azurerm_subnet" "axle-gateway" {
  name                = "GatewaySubnet"
  resource_group_name = "${azurerm_resource_group.axle.name}"

  virtual_network_name = "${azurerm_virtual_network.axle.name}"
  address_prefix       = "${cidrsubnet(var.axle-cidr, 6, 1)}"
}

resource "azurerm_local_network_gateway" "axle-hub-a" {
  name                = "${var.meta-prefix}-axle-hub-a"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  gateway_address = "${var.hub-a-address}"
  address_space   = ["${var.hub-a-subnets}"]
}

resource "azurerm_local_network_gateway" "axle-hub-b" {
  name                = "${var.meta-prefix}-axle-hub-b"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  gateway_address = "${var.hub-b-address}"
  address_space   = ["${var.hub-b-subnets}"]
}

resource "azurerm_public_ip" "axle-gateway" {
  name                = "${var.meta-prefix}-axle-gateway"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "axle" {
  name                = "${var.meta-prefix}-axle"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    public_ip_address_id          = "${azurerm_public_ip.axle-gateway.id}"
    subnet_id                     = "${azurerm_subnet.axle-gateway.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_gateway_connection" "axle-hub-a" {
  name                = "${var.meta-prefix}-axle-hub-a"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.axle.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.axle-hub-a.id}"
  shared_key                 = "${var.hub-a-secret}"
}

resource "azurerm_virtual_network_gateway_connection" "axle-hub-b" {
  name                = "${var.meta-prefix}-axle-hub-b"
  location            = "${var.axle-location}"
  resource_group_name = "${azurerm_resource_group.axle.name}"
  tags                = "${var.meta-tags}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.axle.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.axle-hub-b.id}"
  shared_key                 = "${var.hub-b-secret}"
}

##
## Hubs
##
#
# Not currently supported
#

##
## Spokes
##

resource "azurerm_resource_group" "spoke" {
  name     = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  location = "${var.spoke-location[count.index]}"
  tags     = "${var.meta-tags}"
  count    = "${length(var.spoke-location)}"
}

resource "azurerm_virtual_network" "spoke" {
  name                = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  location            = "${var.spoke-location[count.index]}"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  tags                = "${var.meta-tags}"
  count               = "${length(var.spoke-location)}"

  address_space = ["${cidrsubnet(var.spoke-cidr, 4, count.index)}"]
}

resource "azurerm_subnet" "spoke" {
  name                = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  count               = "${length(var.spoke-location)}"

  virtual_network_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  address_prefix       = "${cidrsubnet(var.spoke-cidr, 6, (4 * count.index))}"
}

resource "azurerm_subnet" "spoke-gateway" {
  name                = "GatewaySubnet"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  count               = "${length(var.spoke-location)}"

  virtual_network_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  address_prefix       = "${cidrsubnet(var.spoke-cidr, 6, (4 * count.index) + 1)}"
}

resource "azurerm_local_network_gateway" "spoke-hub-a" {
  name                = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}-hub-a"
  location            = "${var.spoke-location[count.index]}"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  tags                = "${var.meta-tags}"
  count               = "${length(var.spoke-location)}"

  gateway_address = "${var.hub-a-address}"
  address_space   = ["${var.hub-a-subnets}"]
}

resource "azurerm_local_network_gateway" "spoke-hub-b" {
  name                = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}-hub-b"
  location            = "${var.spoke-location[count.index]}"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  tags                = "${var.meta-tags}"
  count               = "${length(var.spoke-location)}"

  gateway_address = "${var.hub-b-address}"
  address_space   = ["${var.hub-b-subnets}"]
}

resource "azurerm_public_ip" "spoke-gateway" {
  name                = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}-gateway"
  location            = "${var.spoke-location[count.index]}"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  tags                = "${var.meta-tags}"
  count               = "${length(var.spoke-location)}"

  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "spoke" {
  name                = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  location            = "${var.spoke-location[count.index]}"
  resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
  tags                = "${var.meta-tags}"
  count               = "${length(var.spoke-location)}"

  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    public_ip_address_id          = "${element(azurerm_public_ip.spoke-gateway.*.id, count.index)}"
    subnet_id                     = "${element(azurerm_subnet.spoke-gateway.*.id, count.index)}"
    private_ip_address_allocation = "Dynamic"
  }
}

#resource "azurerm_virtual_network_gateway_connection" "spoke-hub-a" {
#	name = "${var.meta-prefix}-spoke-hub-a"
#	location = "${var.spoke-location[count.index]}"
#	resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
#	tags = "${var.meta-tags}"
#
#	type = "IPsec"
#	virtual_network_gateway_id = "${azurerm_virtual_network_gateway.spoke.id}"
#	local_network_gateway_id = "${azurerm_local_network_gateway.spoke-hub-a.id}"
#	shared_key = "${var.hub-a-secret}"
#}
#
#resource "azurerm_virtual_network_gateway_connection" "spoke-hub-b" {
#	name = "${var.meta-prefix}-spoke-hub-b"
#	location = "${var.spoke-location[count.index]}"
#	resource_group_name = "${var.meta-prefix}-spoke-${var.spoke-location[count.index]}"
#	tags = "${var.meta-tags}"
#
#	type = "IPsec"
#	virtual_network_gateway_id = "${azurerm_virtual_network_gateway.spoke.id}"
#	local_network_gateway_id = "${azurerm_local_network_gateway.spoke-hub-b.id}"
#	shared_key = "${var.hub-b-secret}"
#}

