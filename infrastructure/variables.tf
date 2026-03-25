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


# ACR
variable "acr_sku" {
  type        = string
  default     = "Premium"
}

# Container Apps
variable "aca_subnet_prefix" {
  type        = string
  description = "The address prefix for the Container Apps subnet"
}
