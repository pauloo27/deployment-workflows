output "vpn_endpoint_id" {
  value       = aws_ec2_client_vpn_endpoint.oli_vpn.id
  description = "Client VPN Endpoint ID"
}

output "vpn_client_cidr" {
  value       = var.vpn_client_cidr
  description = "VPN client CIDR block"
}
