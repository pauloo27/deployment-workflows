resource "aws_security_group" "vpn" {
  name        = "oli-vpn-sg-${var.env}"
  description = "Security group for VPN network association"
  vpc_id      = var.vpc_id

  # Allow all inbound from VPN clients
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_client_cidr]
    description = "Allow all from VPN clients"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "oli-vpn-sg-${var.env}"
    Env  = var.env
  }
}

resource "aws_ec2_client_vpn_endpoint" "oli_vpn" {
  description            = "Oli Client VPN ${var.env}"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.vpn_client_cidr
  security_group_ids     = [aws_security_group.vpn.id]
  vpc_id                 = var.vpc_id

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_certificate_arn
  }

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "oli-vpn-${var.env}"
    Env  = var.env
  }
}

resource "aws_ec2_client_vpn_network_association" "oli_vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.oli_vpn.id
  subnet_id              = var.subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "oli_vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.oli_vpn.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
}
