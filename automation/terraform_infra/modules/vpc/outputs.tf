output "vpc_id" {
  value = aws_vpc.main.id
}

output "onprem_subnet_ids" {
  value = values(aws_subnet.on_prem).*.id
}

output "eks_subnet_ids" {
  value = values(aws_subnet.on_prem).*.id
}