variable "vpc_cidr" {
  type        = string
  description = "value of the vpc cidr"
}

variable "onprem_subnets" {
  type = list(object({
    name   = string,
    subnet = string,
    az     = string
  }))
  description = "cidr of the onprem subnet"
}

variable "eks_subnets" {
  type = list(object({
    name   = string,
    subnet = string,
    az     = string
  }))
  description = "subnets for the eks cluster"
}
