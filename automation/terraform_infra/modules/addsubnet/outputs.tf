output "public_subnets" {
  value = values(aws_subnet.public).*.id
}