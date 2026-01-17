output "subnet_id" {
  value       = aws_subnet.private.id
  description = "Private subnet ID"
}

output "instance_id" {
  value       = aws_instance.k3s.id
  description = "EC2 instance ID"
}

output "private_ip" {
  value       = aws_instance.k3s.private_ip
  description = "EC2 instance private IP"
}
