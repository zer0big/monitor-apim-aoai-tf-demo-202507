# 프로젝트 개요

아래는 구성하고자 하는 Azure API Management와 Azure OpenAI 연동 아키텍처입니다:

![APIM AOAI 아키텍처](https://github.com/zer0big/monitor-apim-aoai-tf-demo-202507/blob/main/20250711_APIM-AOAI.png)

# 실행방법

먼저 Azure SA로서 Azure CLI, Git 및 Terraform 등 업무 수행 상 환경 구성이 안된 경우, 다음 블로그 글을 참고하여 Azure SA 업무 환경을 구성한다.
1. [Azure SA 업무 환경 구성 - Part 1](https://zerobig-k8s.tistory.com/152)  
2. [Azure SA 업무 환경 구성 - Part 2](https://zerobig-k8s.tistory.com/153)

![리소스 배포 결과](https://github.com/zer0big/monitor-apim-aoai-tf-demo-202507/blob/main/20250721_104240.png)


1. Terminal 실행
2. git clone https://github.com/zer0big/monitor-apim-aoai-tf-demo-202507.git
3. cd monitor-apim-aoai-tf-demo-202507
4. main.tf 13라인 본인의 구독ID 삽입   
5. terraform init
6. terraform plan
7. terraform apply --auto-approve
