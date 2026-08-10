output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "app_subnets" {
  description = "IDs of the application subnets"
  value       = [aws_subnet.app_az1.id, aws_subnet.app_az2.id]
}

output "db_subnets" {
  description = "IDs of the database subnets"
  value       = [aws_subnet.db_az1.id, aws_subnet.db_az2.id]
}

output "management_subnets" {
  description = "IDs of the management subnets"
  value       = [aws_subnet.management_az1.id, aws_subnet.management_az2.id]
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = aws_nat_gateway.nat.id
}
