# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}


# ---------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets."
  value       = aws_subnet.public[*].cidr_block
}


# ---------------------------------------------------------
# Private EKS Subnets
# ---------------------------------------------------------

output "private_subnet_ids" {
  description = "IDs of the private application/EKS subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private application/EKS subnets."
  value       = aws_subnet.private[*].cidr_block
}


# ---------------------------------------------------------
# Database Subnets
# ---------------------------------------------------------

output "database_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = aws_subnet.database[*].id
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of the private database subnets."
  value       = aws_subnet.database[*].cidr_block
}


# ---------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.this.id
}


# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}