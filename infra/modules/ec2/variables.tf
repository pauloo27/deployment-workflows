variable "env" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block to derive subnet CIDR"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t4g.small"
}

variable "route_table_id" {
  type        = string
  description = "Route table ID to associate with subnet"
}

variable "vpn_client_cidr" {
  type        = string
  description = "VPN client CIDR block for security group rules"
}
