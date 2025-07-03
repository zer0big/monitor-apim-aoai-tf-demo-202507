output "resource_group_name" {
  description = "The name of the resource group created."
  value       = azurerm_resource_group.rg.name
}

output "apim_endpoint" {
  description = "The endpoint URL of the API Management service."
  value       = azurerm_api_management.apim.gateway_url
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.law.id
}

output "application_insights_id" {
  description = "The ID of the Application Insights instance."
  value       = azurerm_application_insights.appi.id
}

output "openai_endpoints" {
  description = "The endpoints of the created Azure OpenAI services"
  value = {
    for key, service in azurerm_cognitive_account.aoai :
    key => service.endpoint
  }
}
