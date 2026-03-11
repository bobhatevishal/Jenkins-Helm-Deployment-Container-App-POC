output "cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  sensitive   = true
}

output "aks_identity_object_id" {
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "kubelet_identity" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0]
}

output "node_resource_group" {
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.aks.id
}

