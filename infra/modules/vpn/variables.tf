variable "env" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where VPN will be attached"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for VPN association"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block to authorize access"
}

variable "server_certificate_arn" {
  type        = string
  description = "ARN of server certificate in ACM"
}

variable "client_certificate_arn" {
  type        = string
  description = "ARN of client certificate in ACM"
}

variable "vpn_client_cidr" {
  type        = string
  description = "CIDR block for VPN clients"
  default     = "10.10.0.0/22"
}
