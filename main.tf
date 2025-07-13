# Terraform 및 Azure Provider 설정
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" // <-- Provider 버전을 4.0 이상으로 설정합니다.
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "Your Subscription ID" // !!! 배포 시 구독 ID 변경 !!! --> 상용환경에서는 환경 변수 등 처리 필요.
}

# 리소스 그룹 생성
resource "azurerm_resource_group" "rg" {
  name        = var.resource_group_name
  location    = var.location
}

# API Management 인스턴스 생성
resource "azurerm_api_management" "apim" {
  name                = var.apim_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
}

# Log Analytics Workspace 생성
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.resource_group_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights 생성 (APIM Diagnostic Setting과는 별개로 APIM 내부 로깅을 위함)
resource "azurerm_application_insights" "appins" {
  name                = "${var.resource_group_name}-appins"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}


# ==============================================================================
# APIM Diagnostic Setting 추가 (Log Analytics Workspace로 전송)
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "apim_diag_settings" {
  name                           = "${azurerm_api_management.apim.name}-diag"
  target_resource_id             = azurerm_api_management.apim.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id # Log Analytics Workspace ID

  # APIM에서 전송할 로그 카테고리 (Provider 4.0+ 문법: enabled_log 사용)
  enabled_log {
    category = "GatewayLogs" # API 요청/응답에 대한 로그
    # retention_policy 블록은 더 이상 여기에 포함되지 않습니다.
  }
//  enabled_log {
//    category = "AuditLogs" # APIM 구성 변경에 대한 감사 로그 // 지원 안함 에러 발생
//  }
  // enabled_log { // 'ConsumptionLogs'는 APIM Standard/Premium SKU에서 지원되지 않으므로 제외합니다.
  //   category = "ConsumptionLogs"
  // }

  // APIM에서 전송할 메트릭 카테고리 (Provider 4.0+ 문법: enabled_metric 사용)
//  enabled_metric {
//    category = "AllMetrics" // 모든 플랫폼 메트릭 (CPU, 메모리, 요청 수 등)
//  }
}


# ==============================================================================
# APIM과 Application Insights 연동 (API 호출 트레이스 및 데이터 로깅)
# ==============================================================================
# APIM Logger 생성 (Application Insights 연결)
resource "azurerm_api_management_logger" "apim_ai_logger" {
  name                = "application-insights-logger"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appins.id

  application_insights {
    instrumentation_key = azurerm_application_insights.appins.instrumentation_key
  }
}

# APIM 진단 설정 (모든 API 트래픽 로깅)
# 이 진단은 azurerm_monitor_diagnostic_setting과는 별개로 APIM 게이트웨이 수준의 상세 진단을 Application Insights로 보냅니다.
resource "azurerm_api_management_diagnostic" "apim_diagnostic" {
  identifier            = "applicationinsights" // 서비스 전체 진단을 위한 고유 식별자
  resource_group_name   = azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.apim.name
  api_management_logger_id = azurerm_api_management_logger.apim_ai_logger.id

  sampling_percentage   = 100 // 모든 요청 로깅
  always_log_errors     = true
  log_client_ip         = true

  frontend_request {
    headers_to_log       = ["User-Agent", "Host", "Content-Type"] // 추가할 헤더 명시
  }
  frontend_response {
    headers_to_log       = ["Content-Type"]
  }
  backend_request {
    headers_to_log       = ["User-Agent", "Host", "Content-Type"] // 추가할 헤더 명시
  }
  backend_response {
    headers_to_log       = ["Content-Type"]
  }
}


# 2개의 Azure OpenAI 서비스 생성 (for_each 사용)
resource "azurerm_cognitive_account" "aoai" {
  for_each = var.openai_services

  name                = each.value.name
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = each.value.sku_name

  custom_subdomain_name = each.value.name
  public_network_access_enabled = true

}

# 2개의 gpt-4o 모델 배포 (for_each 사용)
resource "azurerm_cognitive_deployment" "aoai_deployment" {
  for_each = var.openai_services

  name                 = each.value.deployment_name
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
