resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-EOT
    [bastion]
    bastion-host ansible_host=${local.bastion_pub_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    [master]
    master-node ansible_host=${aws_instance.k3s_master.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    [worker]
    web-worker-01 ansible_host=${aws_instance.web_worker_1.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}
    web-worker-02 ansible_host=${aws_instance.web_worker_2.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}
    db-node ansible_host=${aws_instance.db_worker.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}

    [k3s_nodes:children]
    master
    worker

    [k3s_nodes:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@${local.bastion_pub_ip} -i ${var.private_key_path}"'
  EOT
}
