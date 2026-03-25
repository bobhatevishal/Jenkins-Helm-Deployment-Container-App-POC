variable "name" {
  type        = string
  description = "The name of the Azure Container Apps Environment."
}

variable "location" {
  type        = string
  description = "The Azure region to deploy the environment in."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "infrastructure_subnet_id" {
  type        = string
  description = "The ID of the subnet to integrate the ACA environment into."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources."
}
