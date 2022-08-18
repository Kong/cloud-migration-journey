variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "igw_id" {
  type        = string
  description = "id of igw"
}

variable "public_subnets" {
  type = list(object({
    name   = string,
    subnet = string,
    az     = string
  }))
  description = "cidr of the public subnets to create"
}