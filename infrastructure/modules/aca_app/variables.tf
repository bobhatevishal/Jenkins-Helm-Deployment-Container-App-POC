variable "name" {
  type        = string
  description = "The name of the Container App."
}

variable "location" {
  type        = string
  description = "The Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "container_app_environment_id" {
  type        = string
  description = "The ID of the Container Apps Environment."
}

variable "acr_id" {
  type        = string
  description = "The ID of the Azure Container Registry to assign AcrPull role."
}

variable "registry_server" {
  type        = string
  description = "The login server for the container registry."
}

variable "container_name" {
  type        = string
  description = "The name of the container app container."
  default     = "app"
}

variable "container_image" {
  type        = string
  description = "The image to use for the container app."
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "container_cpu" {
  type        = number
  description = "CPU cores for the container."
  default     = 0.5
}

variable "container_memory" {
  type        = string
  description = "Memory for the container."
  default     = "1Gi"
}

variable "container_port" {
  type        = number
  description = "The target port for the container app ingress."
  default     = 80
}

variable "is_http" {
  type        = bool
  description = "Whether the app uses HTTP ingress with HTTP health probes."
  default     = true
}

variable "external_enabled" {
  type        = bool
  description = "Whether the app is accessible from the internet."
  default     = true
}

variable "min_replicas" {
  type        = number
  description = "The minimum number of replicas for scaling."
  default     = 1
}

variable "max_replicas" {
  type        = number
  description = "The maximum number of replicas for scaling."
  default     = 5
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign."
}
