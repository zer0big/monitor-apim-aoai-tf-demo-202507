# variables.tf
variable "resource_group_name" {
  description = "리소스 그룹의 이름"
  type        = string
  default     = "rg-tf-apim-aoai-demo"
}

variable "location" {
  description = "리소스가 배포될 Azure 지역"
  type        = string
  default     = "eastus"
}

variable "apim_name" {
  description = "API Management 인스턴스의 이름"
  type        = string
  default     = "tf-apim-aoai-demo-20250713"
}

variable "apim_publisher_name" {
  description = "APIM 게시자 이름"
  type        = string
  default     = "ZEROBIG"
}

variable "apim_publisher_email" {
  description = "APIM 게시자 이메일"
  type        = string
  default     = "zerobig.kim@gmail.com"
}

variable "apim_sku_name" {
  description = "APIM의 SKU. (예: Developer_1, Basic_1, Standard_1, Premium_1)"
  type        = string
  default     = "Developer_1"
}

variable "openai_services" {
  description = "A map of Azure OpenAI service configurations."
  type = map(object({
    location        = string
    sku_name        = string
    deployment_name = string
    model_name      = string
    model_version   = string
    capacity        = number
  }))
  default = {
    service01 = { 
      location        = "eastus"
      sku_name        = "S0"
      deployment_name = "gpt-4o"
      model_name      = "gpt-4o"
      model_version   = "2024-11-20" # 최신 gpt-4o 버전 확인 후 사용
      capacity        = 20 // 예시: 20 PTU
},
    service02 = {
      location        = "westus"
      sku_name        = "S0"
      deployment_name = "gpt-4o"
      model_name      = "gpt-4o"
      model_version   = "2024-11-20" # 최신 gpt-4o 버전 확인 후 사용
      capacity        = 20 // 예시: 20 PTU
    }
  }
}
