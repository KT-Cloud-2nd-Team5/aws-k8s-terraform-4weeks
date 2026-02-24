# [1] 접속 명령어 모음
output "A_connection_commands" {
  description = "각 서버 접속을 위한 SSH 명령어 모음"
  value = {
    "1_Bastion_Host" = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.bastion.public_ip}"

    "2_Master_Node" = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no -o ProxyCommand='ssh -i ${var.private_key_path} -W %h:%p ubuntu@${aws_instance.bastion.public_ip}' ubuntu@${aws_instance.k3s_master.private_ip}"

    "3_DB_Worker" = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no -o ProxyCommand='ssh -i ${var.private_key_path} -W %h:%p ubuntu@${aws_instance.bastion.public_ip}' ubuntu@${aws_instance.db_worker.private_ip}"
  }
}

# [2] 클러스터 노드 정보
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
    #    "1_ALB_DNS"       = "http://${aws_lb.main.dns_name}"
    "2_DB_Host"       = aws_instance.db_worker.private_ip
    "3_Proxy_Env_Var" = "export http_proxy=http://${aws_instance.bastion.private_ip}:3128 && export https_proxy=http://${aws_instance.bastion.private_ip}:3128"
  }
}

# [4] Backend
output "D_backend_info" {
  description = "Terraform Backend S3 연결 정보"
  value = {
    bucket_name = data.aws_s3_bucket.tfstate_bucket.id
    region      = data.aws_s3_bucket.tfstate_bucket.region
    arn         = data.aws_s3_bucket.tfstate_bucket.arn
    console_url = "https://s3.console.aws.amazon.com/s3/buckets/${data.aws_s3_bucket.tfstate_bucket.id}?region=${data.aws_s3_bucket.tfstate_bucket.region}"
  }
}

# [5] 검증 스크립트 실행 명령어
output "E_verify_command" {
  description = "Windows PowerShell에서 인프라 검증 스크립트를 바로 실행하는 명령어"
  value       = "powershell -ExecutionPolicy Bypass -File .\\verify_infra.ps1"
}


# -----------------------------------------------------------------------------
# Verification Script (Windows PowerShell용)
# -----------------------------------------------------------------------------
resource "local_file" "verify_script_windows" {
  filename = "${path.module}/verify_infra.ps1"
  content  = <<-EOT
    # ------------------------------------------------------------------
    # [Terraform Verification Script - ASCII Version]
    # ------------------------------------------------------------------
    $KeyPath = "${var.private_key_path}"
    $BastionIP = "${aws_instance.bastion.public_ip}"
    $MasterIP = "${aws_instance.k3s_master.private_ip}"
    $DBIP = "${aws_instance.db_worker.private_ip}"
    $Web1IP = "${aws_instance.web_worker_1.private_ip}"
    $Web2IP = "${aws_instance.web_worker_2.private_ip}"
    $ProxyUrl = "http://${aws_instance.bastion.private_ip}:3128"

    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host " >> Infrastructure Verification Start"
    Write-Host "========================================================" -ForegroundColor Cyan

    # 1. Bastion Host Connection Check
    Write-Host -NoNewline "[1/6] Checking Bastion Host ($BastionIP)... "
    ssh -i $KeyPath -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$BastionIP "echo 'OK'" > $null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "[PASS]" -ForegroundColor Green } else { Write-Host "[FAIL]" -ForegroundColor Red; exit }

    # 2. Private Master Node Connection Check
    Write-Host -NoNewline "[2/6] Checking Private Master Node ($MasterIP)... "
    ssh -i $KeyPath -o StrictHostKeyChecking=no -o ConnectTimeout=5 `
        -o ProxyCommand="ssh -i $KeyPath -W %h:%p ubuntu@$BastionIP" `
        ubuntu@$MasterIP "echo 'OK'" > $null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "[PASS]" -ForegroundColor Green } else { Write-Host "[FAIL]" -ForegroundColor Red; exit }

    # 3. Internet Connectivity Check
    Write-Host -NoNewline "[3/6] Checking Internet on Private Master... "
    ssh -i $KeyPath -o StrictHostKeyChecking=no `
        -o ProxyCommand="ssh -i $KeyPath -W %h:%p ubuntu@$BastionIP" `
        ubuntu@$MasterIP "export http_proxy=$ProxyUrl; export https_proxy=$ProxyUrl; curl -I -s --connect-timeout 5 https://www.google.com" > $null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "[PASS]" -ForegroundColor Green } else { Write-Host "[FAIL] (Check Squid Proxy)" -ForegroundColor Red }

    # 4. Master -> DB Worker Check
    Write-Host -NoNewline "[4/6] Checking Network (Master -> DB Worker)... "
    ssh -i $KeyPath -o StrictHostKeyChecking=no `
        -o ProxyCommand="ssh -i $KeyPath -W %h:%p ubuntu@$BastionIP" `
        ubuntu@$MasterIP "ping -c 2 -W 1 $DBIP" > $null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "[PASS]" -ForegroundColor Green } else { Write-Host "[FAIL]" -ForegroundColor Red }

    # 5. Master -> Web Worker 1 Check
    Write-Host -NoNewline "[5/6] Checking Network (Master -> Web Worker 1)... "
    ssh -i $KeyPath -o StrictHostKeyChecking=no `
        -o ProxyCommand="ssh -i $KeyPath -W %h:%p ubuntu@$BastionIP" `
        ubuntu@$MasterIP "ping -c 2 -W 1 $Web1IP" > $null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "[PASS]" -ForegroundColor Green } else { Write-Host "[FAIL]" -ForegroundColor Red }

    # 6. Master -> Web Worker 2 Check
    Write-Host -NoNewline "[6/6] Checking Network (Master -> Web Worker 2)... "
    ssh -i $KeyPath -o StrictHostKeyChecking=no `
        -o ProxyCommand="ssh -i $KeyPath -W %h:%p ubuntu@$BastionIP" `
        ubuntu@$MasterIP "ping -c 2 -W 1 $Web2IP" > $null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "[PASS]" -ForegroundColor Green } else { Write-Host "[FAIL]" -ForegroundColor Red }

    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host " >> All Checks Completed Successfully!"
    Write-Host "========================================================" -ForegroundColor Cyan
  EOT
}



# -----------------------------------------------------------------------------
# Ansible Inventory Generation (자동 생성)
# -----------------------------------------------------------------------------
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    # 1. Bastion Host (Direct Access)
    [bastion]
    bastion-host ansible_host=${aws_instance.bastion.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    # 2. K3s Master Node (Private IP)
    [master]
    master-node ansible_host=${aws_instance.k3s_master.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    # 3. Web Worker Nodes (Private IP)
    # Public IP가 있지만, 클러스터 내부 통신 일관성을 위해 Bastion을 통해 Private IP로 접근합니다.
    [worker]
    web-worker-01 ansible_host=${aws_instance.web_worker_1.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}
    web-worker-02 ansible_host=${aws_instance.web_worker_2.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    # 4. DB Node (Private IP)
    [db]
    db-node ansible_host=${aws_instance.db_worker.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    # ------------------------------------------------------------------
    # Grouping & Proxy Configuration
    # ------------------------------------------------------------------
    
    # 내부 노드들을 하나의 그룹으로 묶음
    [k3s_nodes:children]
    master
    worker
    db

    # 내부 노드 접속 시 Bastion을 거쳐가도록 설정 (ProxyJump)
    [k3s_nodes:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@${aws_instance.bastion.public_ip} -i ${var.private_key_path}"'
  EOT
}
