output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.ambient_cluster.name
}

output "get_credentials_command" {
  description = "Command to get cluster credentials"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --region=${var.region}"
}
