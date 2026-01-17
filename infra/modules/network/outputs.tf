output "vpc_id" {
  value       = aws_vpc.oli-vpc.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.oli-vpc.cidr_block
  description = "VPC CIDR block"
}

output "route_table_id" {
  value       = aws_route_table.main.id
  description = "Main route table ID"
}
