# -----------------------------------------------------------------------------
# Jenkins controller VM. Terraform provisions the infrastructure; the Ansible
# roles (ansible/) then install and configure Jenkins (Java, the Jenkins apt
# repo, plugins via jenkins-plugin-cli, and Configuration-as-Code).
#
# The startup script only prepares the host to be managed by Ansible (python3
# + python3-apt for the apt module, plus git/curl/gnupg).
# -----------------------------------------------------------------------------

resource "google_compute_address" "jenkins" {
  name   = "${local.name_prefix}-jenkins"
  region = var.region
}

resource "google_compute_instance" "jenkins" {
  name         = "${local.name_prefix}-jenkins"
  machine_type = var.jenkins_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.jenkins_image
      size  = var.root_volume_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.app.id
    access_config {
      nat_ip = google_compute_address.jenkins.address
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {})

  service_account {
    email  = google_service_account.jenkins.email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true

  tags = ["jenkins"]

  labels = {
    workload    = var.workload
    cost_center = var.cost_center
  }

  depends_on = [google_project_service.enabled]
}
