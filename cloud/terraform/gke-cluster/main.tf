# GKE Cluster
resource "google_container_cluster" "ambient_cluster" {
  name     = var.cluster_name
  location = var.region

  network    = var.network_name
  subnetwork = var.subnetwork_name

  # Remover el default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    disk_size_gb = 15
    disk_type    = "pd-balanced"
    machine_type = var.machine_type
  }

  # IP allocation
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.48.0.0/14"
    services_ipv4_cidr_block = "10.52.0.0/16"
  }

  release_channel {
    channel = "UNSPECIFIED"
  }

  # Private cluster config
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  # Disable logging
  logging_config {
    enable_components = []
  }

  deletion_protection = false
}

# Node pool
resource "google_container_node_pool" "default_pool" {
  name     = "${var.cluster_name}-pool"
  cluster  = google_container_cluster.ambient_cluster.name
  location = var.region

  node_count = 1

  autoscaling {
    min_node_count = 0
    max_node_count = 1
  }

  # Node configuration
  node_config {
    machine_type = var.machine_type
    disk_size_gb = 15
    disk_type    = "pd-balanced"
    image_type   = "COS_CONTAINERD"
    spot         = true  # Spot instances

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Metadata to disable legacy endpoints
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Labels
    labels = {
      environment = "hybrid"
      cluster     = var.cluster_name
    }

    # Tags is firewall related
    tags = ["gke-hybrid-node", var.cluster_name]
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = false  # No enables automatic upgrades
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
