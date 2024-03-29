# Kong Migration Journey configuration file

kong_mesh_version       = "2.1.1"
kong_gateway_version    = "3.1.1.3"

# Kong Konnect Settings
konnect_pat                = "<replace-me>"
konnect_runtime_group_name = "default"

#AWS var to avoid collisions
me = "<replace-me>"

# AWS Infrastructure Settings
aws_region = "us-west-2"
vpc_cidr   = "10.0.0.0/23"
onprem_subnets = [
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
eks = {
  private_subnets = ["10.0.0.128/26", "10.0.0.192/26"],
  public_subnets  = ["10.0.1.0/26", "10.0.1.64/26"],
  az              = ["us-west-2a", "us-west-2b"]
}