#Configure the AWS provider
provider "aws" {
  version = "~> 2.0"  
  region  = "eu-west-2"
}

#Configure the VPC and Public Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${var.prefix}-f5-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false

  tags = {
    Environment = "ob1-vpc-teraform"
  }
}
