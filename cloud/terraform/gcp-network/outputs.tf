output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpn_gateway_ip" {
  value = google_compute_address.vpn_ip.address
}

output "shared_secret" {
  value     = random_password.shared_secret.result
  sensitive = true
}
