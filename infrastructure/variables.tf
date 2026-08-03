variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-k8s-learning"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-learning"
}

variable "node_count" {
  description = "Number of worker nodes in the cluster"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_B2als_v2"
}
