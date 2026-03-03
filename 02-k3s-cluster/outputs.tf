# [1] 접속 명령어 모음
output "A_connection_commands" {
  description = "각 서버 접속을 위한 SSH 명령어 모음"
  value = {
    "1_Bastion_Host" = "ssh -i ${var.private_key_path} ubuntu@${local.bastion_pub_ip}"

    "2_Master_Node" = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no -o ProxyCommand='ssh -i ${var.private_key_path} -W %h:%p ubuntu@${local.bastion_pub_ip}' ubuntu@${aws_instance.k3s_master.private_ip}"

    "3_DB_Worker" = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no -o ProxyCommand='ssh -i ${var.private_key_path} -W %h:%p ubuntu@${local.bastion_pub_ip}' ubuntu@${aws_instance.db_worker.private_ip}"
  }
}

#  클러스터 노드 정보
output "B_cluster_nodes" {
  description = "K3s 노드들의 IP 정보"
  value = {
    "Master_Node"   = "Private: ${aws_instance.k3s_master.private_ip}"
    "DB_Worker"     = "Private: ${aws_instance.db_worker.private_ip}"
    "Web_Worker_01" = "Public: ${aws_instance.web_worker_1.public_ip}  (Private: ${aws_instance.web_worker_1.private_ip})"
    "Web_Worker_02" = "Public: ${aws_instance.web_worker_2.public_ip}  (Private: ${aws_instance.web_worker_2.private_ip})"
  }
}

# [3] 설정값
output "C_app_config" {
  description = "설정 참고값"
  value = {
    "1_ALB_DNS"       = "http://${aws_lb.main.dns_name}"
    "2_DB_Host"       = aws_instance.db_worker.private_ip
    "3_Proxy_Env_Var" = "export http_proxy=http://${local.bastion_priv_ip}:3128 && export https_proxy=http://${local.bastion_priv_ip}:3128"
  }
}


