variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Default zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "hybrid-vpc"
}

variable "onprem_cidr" {
  description = "CIDR block for the on-prem network"
  type        = string
}

variable "onprem_ip" {
  description = "On-prem public IP"
  type        = string
}

variable "gcp_subnet_cidr" {
  description = "CIDR block for GCP subnet VPC network"
  type        = string
  default     = "10.10.1.0/24"
}
