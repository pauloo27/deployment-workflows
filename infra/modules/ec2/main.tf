data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_iam_role" "ssm_role" {
  name = "oli-ssm-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "oli-ssm-role-${var.env}"
    Env  = var.env
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "oli-ssm-profile-${var.env}"
  role = aws_iam_role.ssm_role.name

  tags = {
    Name = "oli-ssm-profile-${var.env}"
    Env  = var.env
  }
}

resource "aws_subnet" "private" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)

  tags = {
    Name = "oli-private-subnet-${var.env}"
    Env  = var.env
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = var.route_table_id
}

resource "aws_security_group" "k3s" {
  name        = "oli-k3s-sg-${var.env}"
  description = "Security group for k3s instance"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow k3s API from within VPC (includes VPN traffic)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k3s API from VPC"
  }

  # Allow kubelet from within VPC
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet API from VPC"
  }

  tags = {
    Name = "oli-k3s-sg-${var.env}"
    Env  = var.env
  }
}

resource "aws_instance" "k3s" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k3s.id]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Disable SSH in favor of SSM
    systemctl disable --now ssh

    # Get private IP from instance metadata
    PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

    # Install k3s bound to private IP only
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address $PRIVATE_IP --advertise-address $PRIVATE_IP" sh -
    systemctl enable k3s
  EOF

  tags = {
    Name = "oli-k3s-${var.env}"
    Env  = var.env
  }
}
