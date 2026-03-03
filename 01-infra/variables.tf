variable "pc_public_ips" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "github_org" {
  description = "GitHub 조직명 (Organization Name)"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token (admin:org 권한 필수)"
  type        = string
  sensitive   = true
}
