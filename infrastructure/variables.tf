# Authentication & Subscriptions
variable "subscription_id" {
  type        = string
}

# General
variable "project_name" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "location" {
  type        = string
}

variable "enable_oms_agent" {
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
}

# Networking
variable "vnet_address_space" {
  type        = list(string)
}

variable "public_subnets" {
  type        = map(string)
}

variable "private_subnets" {
  type        = map(string)
}

# AKS
variable "node_count" {
  type        = number
  default     = 2
}

variable "min_count" {
  type        = number
  default     = 1
}

variable "max_count" {
  type        = number
  default     = 5
}

variable "os_disk_size_gb" {
  type        = number
  default     = 30
}

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
}

variable "kubernetes_version" {
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  type        = string
  default     = "Standard"
}


# ACR
variable "acr_sku" {
  type        = string
  default     = "Premium"
}
