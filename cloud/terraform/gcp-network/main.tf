# VPC and subnet
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow-http" {
  name    = "allow-http-from-local"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [var.onprem_cidr]

  target_tags = ["http-server-from-local"]
}

# Classic VPN Gateway and Tunnel
resource "google_compute_vpn_gateway" "vpn_gw" {
  name    = "${var.network_name}-vpn-gw"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_address" "vpn_ip" {
  name   = "${var.network_name}-vpn-ip"
  region = var.region
}

# Forwarding rules for tunnels
resource "google_compute_forwarding_rule" "esp" {
  name        = "${var.network_name}-esp"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gw.self_link
}

resource "google_compute_forwarding_rule" "udp500" {
  name        = "${var.network_name}-udp500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gw.self_link
}

resource "google_compute_forwarding_rule" "udp4500" {
  name        = "${var.network_name}-udp4500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gw.self_link
}

# VPN Tunnel
resource "random_password" "shared_secret" {
  length  = 20
  special = false
}

resource "google_compute_vpn_tunnel" "onprem_tunnel" {
  name          = "onprem-tunnel"
  region        = var.region
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gw.id
  peer_ip       = var.onprem_ip
  shared_secret = random_password.shared_secret.result

  depends_on = [
    google_compute_forwarding_rule.esp,
    google_compute_forwarding_rule.udp500,
    google_compute_forwarding_rule.udp4500,
  ]

  local_traffic_selector  = [var.gcp_subnet_cidr,var.cluster_ipv4_cidr,var.services_ipv4_cidr]
  remote_traffic_selector = [var.onprem_cidr]
}

# Route
resource "google_compute_route" "to_onprem" {
  name                = "route-to-onprem"
  network             = google_compute_network.vpc.name
  dest_range          = var.onprem_cidr
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.onprem_tunnel.id
}

# VM Instance for testing
resource "google_compute_instance" "test_vm" {
  name         = "test-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  tags = google_compute_firewall.allow-http.target_tags

  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash

    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt..."
    sleep 5
    done

    apt-get update
    apt-get install apache2 -y
    vm_hostname="$(curl -H "Metadata-Flavor:Google" \
    http://169.254.169.254/computeMetadata/v1/instance/name)"
    echo "Page served from: $vm_hostname" | \
    tee /var/www/html/index.html
    systemctl restart apache2
  EOF
}
