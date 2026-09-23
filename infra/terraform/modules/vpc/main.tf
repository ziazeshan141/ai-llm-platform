# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}


# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}


# ---------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"

    "kubernetes.io/role/elb" = "1"
  }
}


# ---------------------------------------------------------
# Private Application / EKS Subnets
# ---------------------------------------------------------

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"

    "kubernetes.io/role/internal-elb" = "1"
  }
}


# ---------------------------------------------------------
# Private Database Subnets
# ---------------------------------------------------------

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-database-${count.index + 1}"
  }
}


# ---------------------------------------------------------
# Elastic IP for NAT Gateway
# ---------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }
}


# ---------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id

  # NAT Gateway must be inside a public subnet.
  subnet_id = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }
}


# ---------------------------------------------------------
# Public Route Table
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}


# ---------------------------------------------------------
# Public Internet Route
# ---------------------------------------------------------

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}


# ---------------------------------------------------------
# Public Route Table Associations
# ---------------------------------------------------------

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ---------------------------------------------------------
# Private Application Route Table
# ---------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}


# ---------------------------------------------------------
# Private Internet Access Through NAT
# ---------------------------------------------------------

resource "aws_route" "private_nat" {
  route_table_id = aws_route_table.private.id

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}


# ---------------------------------------------------------
# Private Application Route Table Associations
# ---------------------------------------------------------

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# ---------------------------------------------------------
# Database Route Table
# ---------------------------------------------------------

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-database-rt"
  }
}


# ---------------------------------------------------------
# Database Route Table Associations
# ---------------------------------------------------------

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}