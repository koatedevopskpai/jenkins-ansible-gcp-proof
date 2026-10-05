# -----------------------------------------------------------------------------
# GKE (OPTIONAL, DISABLED BY DEFAULT).
#
# The GKE management fee is ~$73/mo, so it is NOT part of the always-on cost.
# Enable only to demo the Jenkins -> GKE deployment path:
#   terraform apply -var="enable_gke=true"
# deploy, screenshot, then destroy (or apply with enable_gke=false again).
# -----------------------------------------------------------------------------

resource "google_container_cluster" "primary" {
  count    = var.enable_gke ? 1 : 0
  name     = local.name_prefix
  location = var.region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.app.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  initial_node_count = 1

  node_config {
    machine_type = "e2-small"
    labels = {
      workload    = var.workload
      cost_center = var.cost_center
    }
  }

  deletion_protection = false

  depends_on = [google_project_service.enabled]
}
