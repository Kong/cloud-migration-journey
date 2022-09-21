# Kong Migration Journey configuration file

# Kong Konnect Settings
konnect_instance_id = ""
konnect_user        = ""
konnect_pass        = ""
me = "hello-me"

# AWS Infrastructure Settings
aws_region          = "us-west-2"
vpc_cidr            = "10.0.0.0/23"
onprem_subnets      = [
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