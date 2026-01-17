terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "network" {
  source   = "../modules/network"
  vpc_cidr = "10.5.0.0/16"
  env      = "nonprod"
}

module "vpn" {
  source                 = "../modules/vpn"
  vpc_id                 = module.network.vpc_id
  vpc_cidr               = module.network.vpc_cidr
  subnet_id              = module.ec2.subnet_id
  server_certificate_arn = "arn:aws:acm:us-east-2:891376921164:certificate/8d00a9aa-7216-406c-b83f-afadd3a1a842"
  client_certificate_arn = "arn:aws:acm:us-east-2:891376921164:certificate/f03ff63c-6d98-4f71-b55c-1ebe47c977e4"
  env                    = "nonprod"
}

module "ec2" {
  source          = "../modules/ec2"
  vpc_id          = module.network.vpc_id
  vpc_cidr        = module.network.vpc_cidr
  route_table_id  = module.network.route_table_id
  vpn_client_cidr = module.vpn.vpn_client_cidr
  env             = "nonprod"
}
