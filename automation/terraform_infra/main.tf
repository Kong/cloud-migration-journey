terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>3.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.2.3"
    }
  }
}


provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = "migration-journey"
    }
  }
}

provider "tls" {}
provider "local" {}

locals {
  cluster_name = "kong-mesh-cloud"
}


module "vpc" {
  source = "./modules/vpc"

  vpc_cidr       = var.vpc_cidr
  onprem_subnets = var.onprem_subnets
  eks_subnets    = var.eks_subnets
}

resource "tls_private_key" "kong" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_security_group" "main" {
  name        = "migration-journey"
  description = "Kong and Mesh Traffic Rules"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "All TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  depends_on = [
    module.vpc
  ]
}

resource "aws_key_pair" "key_pair" {
  key_name   = "mj-kong"
  public_key = tls_private_key.kong.public_key_openssh
}

data "aws_ami" "amzLinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


resource "aws_instance" "node" {
  for_each = var.nodes

  ami                         = data.aws_ami.amzLinux.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = module.vpc.onprem_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.main.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 8
    volume_type           = "gp2"
  }

  tags = {
    Name = each.key
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "kong-mesh-zone-cp-rds"
  subnet_ids = module.vpc.onprem_subnet_ids

  tags = {
    Name = "kong-mesh-zone-cp-rds"
  }
}
resource "aws_db_instance" "main" {
  allocated_storage   = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  db_name             = "kongmesh"
  username            = "kongmesh"
  password            = "kongmesh"
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
}



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = local.cluster_name
  cluster_version = "1.22"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.eks_subnet_ids

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
  }

  eks_managed_node_groups = {
    one = {
      name = "mj-cloud"

      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 2
      desired_size = 2

      pre_bootstrap_user_data = <<-EOT
      echo 'foo bar'
      EOT

      vpc_security_group_ids = [
        aws_security_group.main.id
      ]
    }
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.kong.private_key_pem
  filename        = "ec2.key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.kong.public_key_pem
  filename        = "ec2.pub"
  file_permission = "0600"
}

resource "local_file" "inventory" {
  content  = templatefile("inventory.tpl", { aws_nodes = aws_instance.node, node_map = var.nodes })
  filename = "inventory"
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "on_prem" {
  value = module.vpc.onprem_subnet_ids
}