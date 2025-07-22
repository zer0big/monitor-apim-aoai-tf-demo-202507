# locals.tf

# 고유 리소스 식별을 위한 무작위 숫자 문자열 생성 (3자리, 숫자만)
resource "random_string" "resource_id_suffix" {
  length  = 3
  special = false
  upper   = false
  numeric = true
}

locals {
  # 기본 접두사 (예: zbho-q4i)
  base_unique_name = "zbho-${random_string.resource_id_suffix.result}"

  # 랜덤 접미사가 포함된 리소스 그룹 이름 (예: RG-ZBHO-Q4I-APIM-AOAI-DEMO)
  final_resource_group_name = upper("RG-ZBHO-${random_string.resource_id_suffix.result}-APIM-AOAI-DEMO")

  # APIM 이름: 전역 고유 
  apim_name = substr(replace(lower("${local.base_unique_name}-apim"), "_", "-"), 0, 50)

  # Log Analytics Workspace 이름 
  law_name = substr(replace(lower("${local.base_unique_name}-law"), "_", "-"), 0, 63)

  # Application Insights 이름
  appins_name = substr(replace(lower("${local.base_unique_name}-appins"), "_", "-"), 0, 255)

  # AOAI 서비스 이름 (예: zbho-q4i-01-aoai)
  key_index_map = {
    for key in keys(var.openai_services) :
    key => format("%02d", tonumber(regex("[0-5]+", key)))
  }

  aoai_final_names = {
    for key, value in var.openai_services :
    key => substr(
      replace(lower("${local.base_unique_name}-${local.key_index_map[key]}-aoai"), "_", "-"),
      0,
      64
    )
  }

  # AOAI Subdomain 이름 (예: zbho-q4i-01-aoaisub)
  aoai_subdomain_names = {
    for key, value in var.openai_services :
    key => substr(
      replace(lower("${local.base_unique_name}-${local.key_index_map[key]}-aoaisub"), "_", "-"),
      0,
      63
    )
  }

  # AOAI 모델 배포 이름 (예: zbho-q4i-gpt-4o)
  aoai_deployment_final_names = {
    for key, value in var.openai_services :
    key => substr(
      replace(lower("${local.base_unique_name}-${value.deployment_name}"), "_", "-"),
      0,
      64
    )
  }

  # APIM Logger 이름 
  apim_ai_logger_name = substr(replace(lower("${local.base_unique_name}-apim-logger"), "_", "-"), 0, 255)

  # APIM 진단 설정 이름 
  apim_diag_settings_name = substr(replace(lower("${local.base_unique_name}-apim-diag"), "_", "-"), 0, 255)
}

