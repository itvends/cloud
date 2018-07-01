<!--
# README.md
# itvends/cloud
# -->

It Vends Cloud
==============

This repository contains configuration and management information for the It Vends Cloud Platform.


Provisioning
------------

Resources are allocated from underlying Cloud providers using [Terraform](https://www.terraform.io/). Public configuration data and module source are stored at [terraform/](terraform/), while private API keys and cached state are kept locally.

Package Repo
------------

Custom software packages for CentOS, FreeBSD, and Ubuntu are managed at packages/

Configuration Data
------------------

System configuration is managed through the Salt state tree.
