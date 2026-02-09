# AWS K3s Cluster Infrastructure with Terraform

이 프로젝트는 Terraform을 사용하여 AWS 서울 리전(`ap-northeast-2`)에 **K3s (Lightweight Kubernetes) 클러스터**를 구축합니다.
보안을 위해 **Bastion Host**를 통해서만 내부 리소스에 접근할 수 있으며, **Ansible 인벤토리**와 **인프라 검증 스크립트**가 자동으로 생성되도록 구성되어 있습니다.

---

## 🏗 아키텍처 개요 (Architecture)

* **Region:** AWS Seoul (`ap-northeast-2`)
* **VPC Network:** `10.0.0.0/16`
  * **Public Subnet:** Bastion Host, Web Workers, ALB
  * **Private Subnet:** K3s Master, DB Worker
* **Components:**
  * **Bastion Host:** 외부 접속의 유일한 통로이자, 내부 노드를 위한 **Squid Proxy** 서버 역할을 수행합니다.
  * **K3s Master:** 클러스터 컨트롤 플레인 (Private IP만 보유).
  * **Web Workers:** ALB(80) -> NodePort(30080)를 통해 트래픽을 처리합니다.
  * **DB Worker:** 데이터베이스 전용 노드.
  * **ALB:** 외부 HTTP 트래픽을 처리하는 로드밸런서.

---

## 🚀 시작하기 (Getting Started)

### 1. 사전 요구 사항
* Terraform v1.0 이상
* AWS CLI (자격 증명 설정 완료)
* SSH Key Pair (`team_project.pem` 파일이 프로젝트 루트에 존재해야 함)

### 2. 환경 변수 설정 (`terraform.tfvars`)
보안상 `terraform.tfvars` 파일은 Git에 포함되지 않습니다. 프로젝트 루트에 파일을 생성하고 아래 내용을 작성하세요.

```hcl
# terraform.tfvars 예시
key_name         = "team_project"         # AWS 콘솔에 등록된 키 페어 이름
private_key_path = "./team_project.pem"   # 로컬 키 파일 경로
aws_profile      = "default"              # AWS CLI 프로필 이름

# SSH 접속을 허용할 팀원들의 공인 IP (보안 그룹 설정용)
pc_public_ips = [
  "123.123.123.123/32", # Member A
  "210.10.20.30/32",    # Member B
]
```

### 3. 실행 방법
```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 인프라 생성
terraform apply
```

---

## ✨ 자동 생성 파일 (Auto-generated Files)

`terraform apply`가 완료되면 작업 편의를 위해 다음 파일들이 자동으로 생성됩니다.

### 1. Ansible Inventory (`inventory.ini`)
Ansible이 Bastion Host를 거쳐 Private Node에 접속할 수 있도록 `ProxyCommand`가 미리 설정된 인벤토리 파일입니다.
* **경로:** `./inventory.ini`
* **그룹:** `[bastion]`, `[master]`, `[worker]`, `[db]`

### 2. 인프라 검증 스크립트 (`verify_infra.ps1`)
구축된 인프라의 네트워크 연결 상태를 즉시 확인할 수 있는 **Windows PowerShell** 스크립트입니다.

* **실행 방법:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\verify_infra.ps1
  ```
* **검증 항목:**
  1. Bastion Host SSH 접속
  2. Bastion -> Private Master Node 터널링 접속
  3. Private Node -> 외부 인터넷 연결 (Squid Proxy 동작 확인)
  4. Master -> 각 Worker/DB 노드 간 내부 통신(Ping)

---

## 📂 프로젝트 구조

```text
.
├── main.tf             # EC2 인스턴스, AMI, User Data(Squid)
├── network.tf          # VPC, Subnet, Route Table, SG, ALB
├── outputs.tf          # 접속 정보 출력 및 파일 생성(inventory, script) 리소스
├── variables.tf        # 변수 정의
├── terraform.tfvars    # 민감한 설정 값
└── README.md           # 프로젝트 문서
```

## 🔍 출력 정보 (Outputs)
배포 완료 시 터미널에 다음 정보가 표시됩니다.

* **a_connection_commands:** 각 서버 SSH 접속 명령어 모음
* **b_cluster_nodes:** 생성된 노드들의 IP 정보
* **c_app_config:** ALB DNS 주소 및 Proxy 환경변수
* **d_verify_command:** 검증 스크립트 실행 명령어
