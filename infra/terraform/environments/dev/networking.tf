# -----------------------------------------------------------------------------
# Platform networking: custom VPC + subnet (with GKE secondary ranges) and
# firewall rules. Jenkins web/SSH are reachable only via the IAP TCP-forwarding
# range (35.235.240.0/20) by default - no 0.0.0.0/0 exposure.
# -----------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  description             = "jenkins-ansible-gcp-proof platform VPC (workload=${var.workload})"
}

resource "google_compute_subnetwork" "app" {
  name                     = "${local.name_prefix}-app"
  network                  = google_compute_network.vpc.id
  region                   = var.region
  ip_cidr_range            = var.vpc_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.10.32.0/20"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.10.64.0/20"
  }
}

# SSH - restricted to IAP (and any extra CIDRs supplied in var.ssh_cidr).
resource "google_compute_firewall" "ssh" {
  name    = "${local.name_prefix}-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.ssh_cidr
  target_tags   = ["jenkins"]
}

# Jenkins web UI - restricted to IAP (and any extra CIDRs supplied in var.ssh_cidr).
resource "google_compute_firewall" "jenkins_web" {
  name    = "${local.name_prefix}-jenkins-web"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = var.ssh_cidr
  target_tags   = ["jenkins"]
}

# Jenkins inbound agents (JNLP) only from inside the VPC.
resource "google_compute_firewall" "jenkins_agents" {
  name    = "${local.name_prefix}-jenkins-agents"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["50000"]
  }
  source_ranges = [var.vpc_cidr]
  target_tags   = ["jenkins"]
}
