# main.tf

# Terraform 및 Azure Provider 설정
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "1199b626-a317-4559-9289-caba7859ee88"
#  subscription_id = "Your Subscription ID" // !!! 배포 시 구독 ID 변경 !!! --> 상용환경에서는 환경 변수 등 처리 필요.
}

provider "random" {
  # random provider는 특별한 설정 불필요
}
# END: ADDED

# 리소스 그룹 생성
resource "azurerm_resource_group" "rg" {
  name     = local.final_resource_group_name
  location = var.location
}

# API Management 인스턴스 생성
resource "azurerm_api_management" "apim" {
  name                = local.apim_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
}

# Log Analytics Workspace 생성
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights 생성 (APIM Diagnostic Setting과는 별개로 APIM 내부 로깅을 위함)
resource "azurerm_application_insights" "appins" {
  name                = local.appins_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}


# ==============================================================================
# APIM Diagnostic Setting 추가 (Log Analytics Workspace로 전송)
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "apim_diag_settings" {
  name                        = local.apim_diag_settings_name
  target_resource_id          = azurerm_api_management.apim.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.law.id

 # Resource specific 테이블 전송
  log_analytics_destination_type = "Dedicated"

  # 로그 카테고리 그룹 (Category groups)
  enabled_log {
    category_group = "audit"
  }

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# ==============================================================================
# APIM과 Application Insights 연동 (API 호출 트레이스 및 데이터 로깅)
# ==============================================================================
# APIM Logger 생성 (Application Insights 연결)
resource "azurerm_api_management_logger" "apim_ai_logger" {
  name                = local.apim_ai_logger_name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appins.id

  application_insights {
    instrumentation_key = azurerm_application_insights.appins.instrumentation_key
  }
}

# APIM 진단 설정 (모든 API 트래픽 로깅)
resource "azurerm_api_management_diagnostic" "apim_diagnostic" {
  identifier          = "applicationinsights"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  api_management_logger_id = azurerm_api_management_logger.apim_ai_logger.id

  sampling_percentage = 100
  always_log_errors   = true
  log_client_ip       = true

  frontend_request {
    headers_to_log    = ["User-Agent", "Host", "Content-Type"]
  }
  frontend_response {
    headers_to_log    = ["Content-Type"]
  }
  backend_request {
    headers_to_log    = ["User-Agent", "Host", "Content-Type"]
  }
  backend_response {
    headers_to_log    = ["Content-Type"]
  }
}


# 2개의 Azure OpenAI 서비스 생성 (for_each 사용)
resource "azurerm_cognitive_account" "aoai" {
  for_each = var.openai_services

  name                = local.aoai_final_names[each.key]
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = each.value.sku_name

  custom_subdomain_name = local.aoai_subdomain_names[each.key]
  public_network_access_enabled = true
}

# 2개의 gpt-4o 모델 배포 (for_each 사용)
resource "azurerm_cognitive_deployment" "aoai_deployment" {
  for_each = var.openai_services

  name                = local.aoai_deployment_final_names[each.key]
  cognitive_account_id = azurerm_cognitive_account.aoai[each.key].id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = "Standard"
    capacity = each.value.capacity
  }
}
