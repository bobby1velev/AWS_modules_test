############################################
# Network
############################################

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.16.0.0/16"
}

resource "aws_subnet" "subnet_1_public" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "public1")
  availability_zone = var.availability_zone_a
  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "subnet_2_public" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "public2")
  availability_zone = var.availability_zone_b
  tags = {
    Name = "public_subnet_2"
  }
}

resource "aws_subnet" "subnet_3_private" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "private1")
  availability_zone = var.availability_zone_a
  tags = {
    Name = "private_subnet_3"
  }
}

resource "aws_subnet" "subnet_4_private" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "private2")
  availability_zone = var.availability_zone_b
  tags = {
    Name = "private_subnet_4"
  }
}

resource "aws_internet_gateway" "terraform_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id
}

resource "aws_eip" "terraform_elip" {
  domain = "vpc"
}

resource "aws_eip" "terraform_elip2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "terraform_nat" {
  allocation_id = aws_eip.terraform_elip.id
  subnet_id     = aws_subnet.subnet_1_public.id

  tags = {
    Name = "My_nat_1"
  }
}

resource "aws_nat_gateway" "terraform_nat2" {
  allocation_id = aws_eip.terraform_elip2.id
  subnet_id     = aws_subnet.subnet_2_public.id

  tags = {
    Name = "My_nat_2"
  }
}

resource "aws_route_table" "terraform_route_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gateway.id
  }
}

resource "aws_route_table" "route_nat" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_nat.id
  }
}

resource "aws_route_table" "route_nat2" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_nat2.id
  }
}

resource "aws_route_table_association" "terraform_associate1" {
  subnet_id      = aws_subnet.subnet_1_public.id
  route_table_id = aws_route_table.terraform_route_gateway.id
}

resource "aws_route_table_association" "terraform_associate2" {
  subnet_id      = aws_subnet.subnet_2_public.id
  route_table_id = aws_route_table.terraform_route_gateway.id
}

resource "aws_route_table_association" "terraform_associate3" {
  subnet_id      = aws_subnet.subnet_3_private.id
  route_table_id = aws_route_table.route_nat.id
}

resource "aws_route_table_association" "terraform_associate4" {
  subnet_id      = aws_subnet.subnet_4_private.id
  route_table_id = aws_route_table.route_nat2.id
}
