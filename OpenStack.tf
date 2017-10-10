provider "packet" {
  auth_token = "${var.packet_api_key}"
}

resource "packet_device" "controller" {
  hostname = "controller"

  operating_system = "ubuntu_16_04"
  plan             = "${var.packet_controller_type}"
  connection {
    user = "root"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.cloud_ssh_public_key_path}")}\""
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"

  public_ipv4_subnet_size  = "29"

  provisioner "remote-exec" {
    inline = [
      "echo ${packet_device.controller.access_private_ipv4} controller >> /etc/hosts"
    ]
  }
}

# split this out so that the dashboard and compute nodes can provision concurrently
resource "null_resource" "controller-openstack" {
  connection {
    host = "${packet_device.controller.access_public_ipv4}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "CommonServerSetup.sh"
    destination = "CommonServerSetup.sh"
  }

  provisioner "file" {
    source      = "ControllerKeystone.sh"
    destination = "ControllerKeystone.sh"
  }

  provisioner "file" {
    source      = "ControllerGlance.sh"
    destination = "ControllerGlance.sh"
  }

  provisioner "file" {
    source      = "ControllerNova.sh"
    destination  = "ControllerNova.sh"
  }

  provisioner "file" {
    source      = "ControllerNeutron.sh"
    destination = "ControllerNeutron.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash CommonServerSetup.sh > CommonServerSetup.out",
      "bash ControllerKeystone.sh > ControllerKeystone.out",
      "bash ControllerGlance.sh > ControllerGlance.out",
      "bash ControllerNova.sh > ControllerNova.out",
      "bash ControllerNeutron.sh > ControllerNeutron.out",
    ]
  }
}

resource "packet_device" "dashboard" {
  hostname = "dashboard"

  operating_system = "ubuntu_16_04"
  plan             = "${var.packet_dashboard_type}"
  connection {
    user = "root"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.cloud_ssh_public_key_path}")}\""

  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"
}

resource "packet_device" "compute" {
  hostname = "${format("compute-%02d", count.index)}"

  count = "${var.openstack_compute_count}"

  operating_system = "ubuntu_16_04"
  plan             = "${var.packet_compute_type}"
  connection {
    user = "root"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.cloud_ssh_public_key_path}")}\""
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"
}

resource "null_resource" "dashboard-openstack" {

  connection {
    host = "${packet_device.dashboard.access_public_ipv4}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "CommonServerSetup.sh"
    destination = "CommonServerSetup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${packet_device.controller.access_private_ipv4} ${packet_device.controller.hostname} >> /etc/hosts",
      "echo ${packet_device.dashboard.access_private_ipv4} ${packet_device.dashboard.hostname} >> /etc/hosts",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "bash CommonServerSetup.sh > CommonServerSetup.out",
    ]
  }
}

resource "null_resource" "compute-openstack" {
  count = "${var.openstack_compute_count}"

  connection {
    host = "${packet_device.compute.*.access_public_ipv4}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "CommonServerSetup.sh"
    destination = "CommonServerSetup.sh"
  }

  provisioner "file" {
    source      = "ComputeNova.sh"
    destination = "ComputeNova.sh"
  }

  provisioner "file" {
    source      = "ComputeNeutron.sh"
    destination = "ComputeNeutron.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${packet_device.controller.access_private_ipv4} ${packet_device.controller.hostname} >> /etc/hosts",
      "echo ${packet_device.compute.*.access_private_ipv4} ${packet_device.compute.*.hostname} >> /etc/hosts",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "bash CommonServerSetup.sh > CommonServerSetup.out",
      "bash ComputeNova.sh > ComputeNova.out",
      "bash ComputeNeutron.sh > ComputeNeutron.out",
    ]
  }
}
