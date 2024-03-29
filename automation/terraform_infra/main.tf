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
      Project = "kong-migration-journey"
      who     = var.me
    }
  }
}

provider "tls" {}
provider "local" {}

locals {
  cluster_name = "${var.me}-kong-mesh-cloud"
  db = {
    name     = "kongmesh"
    username = "kongmesh"
    password = "kongmesh"
  }

  kubeconfig = <<KUBECONFIG


---
apiVersion: v1
clusters:
- cluster:
    server: ${module.eks.cluster_endpoint}
    certificate-authority-data: ${module.eks.cluster_certificate_authority_data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws-iam-authenticator
      args:
        - "token"
        - "--region"
        - "${var.aws_region}"
        - "-i"
        - "${local.cluster_name}"
KUBECONFIG
}

module "vpc_eks" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  cidr    = var.vpc_cidr
  name    = "${var.me}-kong-mesh-migration-journey"
  azs     = var.eks.az

  public_subnets  = var.eks.public_subnets
  private_subnets = var.eks.private_subnets

  create_igw           = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = local.cluster_name
  cluster_version = "1.22"

  vpc_id     = module.vpc_eks.vpc_id
  subnet_ids = module.vpc_eks.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = [aws_security_group.main.id]

  }

  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }
  eks_managed_node_groups = {
    one = {
      name = "${var.me}-kong-mesh"

      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 2
      desired_size = 2

      pre_bootstrap_user_data = <<-EOT
      echo 'foo bar'
      EOT
    }
  }
}

module "on_prem_subnets" {
  source         = "./modules/addsubnet"
  vpc_id         = module.vpc_eks.vpc_id
  igw_id         = module.vpc_eks.igw_id
  public_subnets = var.onprem_subnets
  depends_on = [
    module.vpc_eks
  ]
}


resource "tls_private_key" "kong" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_security_group" "main" {
  name        = "${var.me}-kong-migration-journey"
  description = "Kong and Mesh Traffic Rules"
  vpc_id      = module.vpc_eks.vpc_id

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
    module.vpc_eks
  ]
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.me}-kmj"
  public_key = tls_private_key.kong.public_key_openssh
}

data "aws_ami" "image" {

  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "node" {
  for_each = var.nodes

  ami                         = data.aws_ami.image.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = module.on_prem_subnets.public_subnets[0]
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
  name       = "${var.me}-kong-mesh-zone-cp-rds"
  subnet_ids = module.on_prem_subnets.public_subnets

  tags = {
    Name = "kong-mesh-zone-cp-rds"
  }
}
resource "aws_db_instance" "main" {
  allocated_storage   = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  db_name             = local.db.name
  username            = local.db.username
  password            = local.db.password
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
}


resource "local_file" "private_key" {
  content         = tls_private_key.kong.private_key_pem
  filename        = "out/ec2/ec2.key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.kong.public_key_pem
  filename        = "out/ec2/ec2.pub"
  file_permission = "0600"
}

resource "local_file" "kubeconfig" {
  content         = local.kubeconfig
  filename        = "out/kube/kubeconfig"
  file_permission = "0600"
}

resource "local_file" "inventory" {
  content = templatefile("inventory.yml.tpl", {
    global_cp_node = aws_instance.node["kuma-global-cp"],
    zone_node      = aws_instance.node["runtime-instance"],
    gateway_node   = aws_instance.node["runtime-instance"],
    monolith_node  = aws_instance.node["monolith"]
  })
  filename = "out/ansible/inventory.yml"
}

resource "local_file" "kuma" {
  content = templatefile("kuma.yml.tpl", {
    kong_mesh_version            = var.kong_mesh_version,
    kong_gateway_version         = var.kong_gateway_version,
    kong_license_path            = var.kong_license_path,
    kubeconfig_path              = "out/kube/kubeconfig",
    konnect_pat                  = var.konnect_pat,
    konnect_runtime_group_name   = var.konnect_runtime_group_name,
    global_cp_node               = aws_instance.node["kuma-global-cp"],
    zone_node                    = aws_instance.node["runtime-instance"],
    gateway_node                 = aws_instance.node["runtime-instance"],
    monolith_node                = aws_instance.node["monolith"],
    db_locals                    = local.db,
    db_instance                  = aws_db_instance.main
  })
  filename = "out/ansible/kuma.yml"
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
