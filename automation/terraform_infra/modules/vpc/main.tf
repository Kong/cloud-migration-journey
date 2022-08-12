resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "migration-journey"
  }
}

resource "aws_subnet" "on_prem" {
  for_each = { for subnet in var.onprem_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

resource "aws_subnet" "eks" {
  for_each = { for subnet in var.eks_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "mj-gw"
  }

}

resource "aws_route" "gw" {
  route_table_id         = aws_vpc.main.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

}

resource "aws_route_table_association" "onprem" {
  for_each       = aws_subnet.on_prem
  subnet_id      = each.value.id
  route_table_id = aws_vpc.main.main_route_table_id
}

resource "aws_route_table_association" "eks" {
  for_each       = aws_subnet.eks
  subnet_id      = each.value.id
  route_table_id = aws_vpc.main.main_route_table_id
}