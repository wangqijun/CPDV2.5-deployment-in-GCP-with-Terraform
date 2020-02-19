resource "google_compute_disk" "worker_docker" {
  count        = "${var.worker["count"]}"
  name         = "${format("worker%02d-dockervol", count.index + 1) }"
  type         = "pd-ssd"
  size         = 200
  labels = {
      owner =  "qijun"     
    }
  zone         = "${var.gcp_zone}"
}
resource "google_compute_disk" "nfs_disk" {
  count        = "${var.nfs["count"]}"
  name         = "${format("nfs%02d-disk", count.index + 1) }"
  type         = "pd-ssd"
  size         = 1000
  labels = {
      owner =  "qijun"     
    }
  zone         = "${var.gcp_zone}"
}
resource "google_compute_disk" "master_docker" {
  count        = "${var.master["count"]}"
  name         = "${format("master%02d-dockervol", count.index + 1) }"
  type         = "pd-ssd"
  size         = 200
  labels = {
      owner =  "qijun"     
    }
  zone         = "${var.gcp_zone}"
}
resource "google_compute_disk" "infra_docker" {
  count        = "${var.infra["count"]}"
  name         = "${format("infra%02d-dockervol", count.index + 1) }"
  type         = "pd-ssd"
  size         = 200
  labels = {
      owner =  "qijun"     
    }
  zone         = "${var.gcp_zone}"
}
resource "google_compute_disk" "master_glusterfs" {
  count        = "${var.master["count"]}"
  name         = "${format("master%02d-glusterfs", count.index + 1) }"
  type         = "pd-ssd"
  size         = 200
  labels = {
      owner =  "qijun"
    }
  zone         = "${var.gcp_zone}"
}

resource "google_compute_instance" "bastion" {
  count = "${var.bastion["count"]}"
  name = "bastion"
  #domain       = "${var.domain}"
  machine_type = "n1-standard-2"
  zone = "${var.gcp_zone}"
  tags = ["bastion-qijun"]
  labels = {
      owner =  "qijun"     
    }
  boot_disk {
    initialize_params {
      image = "${var.gcp_amis}"
      size = "${var.bastion["disk_size"]}"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.public.name}"
    access_config {
        # Ephemeral
    }
  }
  metadata_startup_script = "${data.template_file.sysprep-bastion.rendered}"
  metadata = {
    sshKeys = "centos:${file(var.bastion_key_path)}"
  }
}

resource "google_compute_instance" "nfs" {
  count = "${var.nfs["count"]}"
  name = "${format("nfs%02d", count.index + 1) }"
  #domain       = "${var.domain}"
  machine_type = "n1-standard-2"
  zone = "${var.gcp_zone}"
  tags = ["master-qijun"]
  labels = {
      owner =  "qijun"     
    }
  boot_disk {
    initialize_params {
      image = "${var.gcp_amis}"
      size = "${var.nfs["disk_size"]}"
    }
  }
  attached_disk {
    source = "${element(google_compute_disk.nfs_disk.*.self_link, count.index)}"
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.private.name}"
  }
  metadata = {
    sshKeys = "centos:${file(var.bastion_key_path)}"
  }
}
resource "google_compute_instance" "master" {
  count = "${var.master["count"]}"
  name = "${format("master%02d", count.index + 1) }"
  #domain       = "${var.domain}"
  machine_type = "n1-standard-8"
  zone = "${var.gcp_zone}"
  tags = ["master-qijun"]
  labels = {
      owner =  "qijun"     
    }
  boot_disk {
    initialize_params {
      image = "${var.gcp_amis}"
      size = "${var.master["disk_size"]}"
    }
  }
  attached_disk {
    source = "${element(google_compute_disk.master_docker.*.self_link, count.index)}"
  }
  attached_disk {
    source = "${element(google_compute_disk.master_glusterfs.*.self_link, count.index)}"
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.public.name}"
    access_config {
        # Ephemeral
    }
  }
  metadata = {
    sshKeys = "centos:${file(var.bastion_key_path)}"
  }

 /* provisioner "file" {
     source = "./helper_scripts/user-setup.sh"
     destination = "/tmp/disk.sh"
   }

  provisioner "remote-exec" {
    inline = [
              "bash -x /tmp/disk.sh /dev/sdb /ibm"
             ]

  }*/

}
resource "google_compute_instance" "infra" {
  count = "${var.infra["count"]}"
  name = "${format("infra%02d", count.index + 1) }"
  #domain       = "${var.domain}"
  machine_type = "n1-standard-8"
  zone = "${var.gcp_zone}"
  tags = ["infra-qijun"]
  labels = {
      owner =  "qijun"     
    }
  boot_disk {
    initialize_params {
      image = "${var.gcp_amis}"
      size = "${var.infra["disk_size"]}"
    }
  }
  attached_disk {
    source = "${element(google_compute_disk.infra_docker.*.self_link, count.index)}"
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.private.name}"
  }
  metadata =  {
    sshKeys = "centos:${file(var.bastion_key_path)}"
  }
}
resource "google_compute_instance" "worker" {
  count = "${var.worker["count"]}"
  name = "${format("worker%02d", count.index + 1) }"
  #domain       = "${var.domain}"
  machine_type = "n1-standard-16"
  zone = "${var.gcp_zone}"
  tags = ["worker-qijun"]
  labels = {
      owner =  "qijun"     
    }
  boot_disk {
    initialize_params {
      image = "${var.gcp_amis}"
      size = "${var.worker["disk_size"]}"
    }
  }
  attached_disk {
    source = "${element(google_compute_disk.worker_docker.*.self_link, count.index)}"
  }


  network_interface {
    subnetwork = "${google_compute_subnetwork.private.name}"
  }
  metadata = {
    sshKeys = "centos:${file(var.bastion_key_path)}"
  }
}
