provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "Fql@dm1n"
  vsphere_server = "vcs.fql.com"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "FQLDatacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore2"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "cluster"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VLAN1963"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "ubuntutemp"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "terraform"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "clone" {
  name             = var.deploymentname
  annotation       = var.deploymentname
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = var.no_cpus
  memory   = 1024
  guest_id = "ubuntu64Guest"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    }
  provisioner "local-exec" {
    command =  "hostname"
    on_failure = continue
  }
  provisioner "local-exec" {
    command =  "ansible --version"
    on_failure = continue
  }
}
variable "no_cpus" {
  type = string
}
variable "deploymentname" {
  type = string
}

output "ipaddress" {
  value = vsphere_virtual_machine.clone.default_ip_address
}
