data "aws_vpc" "main" {
    id = var.vpc_id
}

data "aws_internet_gateway" "gw" {
  internet_gateway_id = var.igw_id
}
resource "aws_subnet" "public" {
  for_each = { for subnet in var.public_subnets : subnet.name => subnet }

  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = each.value.subnet
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = data.aws_internet_gateway.gw.id
  }
  tags = {
      Name = "on-prem public route table"
  }

}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}