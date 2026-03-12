variable "cluster_name" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "location" {
  type        = string
}

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

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
}

variable "os_disk_size_gb" {
  type        = number
  default     = 30
}

variable "kubernetes_version" {
  type        = string
  default     = null
}

variable "sku_tier" {
  type        = string
  default     = "Standard"
}

variable "acr_id" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

variable "appgw_subnet_id" {
  type        = string
}

variable "tags" {
  type        = map(string)
}
