variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  default     = "gke-ambient-multicluster"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "hybrid-vpc"
}

variable "subnetwork_name" {
  description = "VPC subnetwork name"
  default     = "hybrid-vpc-subnet"
}

variable "machine_type" {
  description = "Machine type for nodes"
  default     = "n2-standard-4"
}
