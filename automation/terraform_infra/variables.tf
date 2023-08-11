variable "aws_region" {
  type        = string
  description = "aws region to deploy demo aws infra"
  default     = "us-west-2"
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
  default = "10.0.0.0/23"
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
      "az" : "us-west-2a"
    },
    {
      "name" : "on-prem-2"
      "subnet" : "10.0.0.64/26",
      "az" : "us-west-2b"
    }
  ]
}

variable "eks" {
  type = object({
    private_subnets = list(string),
    public_subnets  = list(string),
    az              = list(string),
    cluster_version = string
  })
  default = {
    private_subnets = ["10.0.0.128/26", "10.0.0.192/26"],
    public_subnets  = ["10.0.1.0/26", "10.0.1.64/26"],
    az              = ["us-west-2a", "us-west-2b"], 
    cluster_version = "1.27"
  }
}

variable "me" {
  type        = string
  description = "auto personalization of kong migration journey demo environment infrastructure"
  default     = "me"
}


variable "konnect_pat" {
  type        = string
  description = "Kong Konnect PAT"
  nullable    = false
}

variable "konnect_runtime_group_name" {
  type        = string
  description = "Kong Konnect Runtime Group Name"
  nullable    = false
  default     = "default"
}

variable "kong_mesh_version" {
  type        = string
  description = "version of Kong Mesh that will be installed"
  default     = "2.1.1"
}

variable "kong_gateway_version" {
  type        = string
  description = "version of Kong Gateway / Dataplane that will be deployed"
  default     = "3.1.1.3"
}

variable "kong_license_path" {
  type        = string
  description = "path to the kong mesh license"
  default     = ""
}
