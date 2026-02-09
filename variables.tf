# [1] PC의 공인 IP (보안 그룹 설정용)
variable "pc_public_ips" {
  description = "public ips for security group"
  type        = list(string)
}

# [2] AWS에 이미 등록된 키 페어 이름 (예: my-existing-key)
variable "key_name" {
  description = "AWS Console EC2 Key Pair Name"
  type        = string
}

# [3] 내 컴퓨터에 있는 .pem 파일 경로 (접속 명령어 출력용)
variable "private_key_path" {
  description = "Local path to private key file (e.g., ./my-key.pem)"
  type        = string
}
# [4] aws 사용 계정 (.aws/.credential 안에서 설정한 이름)
variable "aws_profile" {
  type    = string
  default = "default"
}
