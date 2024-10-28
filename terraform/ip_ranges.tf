variable "ec2_instance_connect_ip_ranges" {
  default = [
    {
      ip_prefix = "3.120.181.40/29"
      region    = "eu-central-1"
    },
    {
      ip_prefix = "16.63.77.8/29"
      region    = "eu-central-2"
    },
    {
      ip_prefix = "13.48.4.200/30"
      region    = "eu-north-1"
    },
    {
      ip_prefix = "15.161.135.164/30"
      region    = "eu-south-1"
    },
    {
      ip_prefix = "18.101.90.48/29"
      region    = "eu-south-2"
    },
    {
      ip_prefix = "18.202.216.48/29"
      region    = "eu-west-1"
    },
    {
      ip_prefix = "3.8.37.24/29"
      region    = "eu-west-2"
    },
    {
      ip_prefix = "35.180.112.80/29"
      region    = "eu-west-3"
    },
    {
      ip_prefix = "18.206.107.24/29"
      region    = "us-east-1"
    },
    {
      ip_prefix = "3.16.146.0/29"
      region    = "us-east-2"
    },
    {
      ip_prefix = "13.52.6.112/29"
      region    = "us-west-1"
    },
    {
      ip_prefix = "18.237.140.160/29"
      region    = "us-west-2"
    },
    {
      ip_prefix = "18.252.4.0/30"
      region    = "us-gov-east-1"
    },
    {
      ip_prefix = "15.200.28.80/30"
      region    = "us-gov-west-1"
    },
    {
      ip_prefix = "35.183.92.176/29"
      region    = "ca-central-1"
    },
    
    {
      ip_prefix = "***" # user's ip from dynamic input
      region    = "###" # user's aws region from dynamic input
    }
  ]
}
