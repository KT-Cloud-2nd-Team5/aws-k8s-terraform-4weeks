# k3s-cluster layer에 전달
output "vpc_id" {
  value = aws_vpc.main.id
}
output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}
output "public_subnet_a" {
  value = aws_subnet.public_a.id
}
output "public_subnet_c" {
  value = aws_subnet.public_c.id
}
output "private_subnet_a" {
  value = aws_subnet.private_a.id
}
output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}
