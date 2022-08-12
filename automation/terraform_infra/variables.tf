variable "aws_region" {
  type        = string
  description = "aws region to deploy demo aws infra"
  default     = "us-west-1"
  nullable    = false
}

variable "nodes" {
  type = map(any)

  default = {
    "runtime-instance" = "on_prem"
    "monolith"         = "on_prem"
    "kuma-global-cp"   = "cloud"
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "onprem_subnets" {
  type = list(object({
    name   = string,
    subnet = string,
    az     = string
  }))
  default = [
    {
      "name" : "on-prem-1",
      "subnet" : "10.0.0.0/26",
      "az" : "us-west-1a"
    },
    {
      "name" : "on-prem-2"
      "subnet" : "10.0.0.64/26",
      "az" : "us-west-1b"
    }
  ]
}

variable "eks_subnets" {
  type = list(object({
    name   = string,
    subnet = string,
    az     = string
  }))
  default = [
    {
      "name" : "cloud-1"
      "subnet" : "10.0.0.128/26",
      "az" : "us-west-1a"
    },
    {
      "name" : "cloud-2"
      "subnet" : "10.0.0.192/26",
      "az" : "us-west-1b"
    }
  ]
}