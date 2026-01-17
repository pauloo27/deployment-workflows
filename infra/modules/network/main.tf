resource "aws_vpc" "oli-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "oli-vpc-${var.env}"
    Env  = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.oli-vpc.id

  tags = {
    Name = "oli-igw-${var.env}"
    Env  = var.env
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.oli-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "oli-rt-${var.env}"
    Env  = var.env
  }
}
