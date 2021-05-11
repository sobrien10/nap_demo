#Configure the AWS provider
provider "aws" {
  version = "~> 2.2"  
  region  = "eu-west-2"
  shared_credentials_file = "/Users/stobrien/.aws/creds"
  profile = "default"
}

#Configure the VPC and Public Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${var.prefix}-f5-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "ob1-vpc-teraform"
  }
}

#Configure the security Group for management and application access
resource "aws_security_group" "f5" {
  name   = "${var.prefix}-f5"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["176.25.98.118/32"]
  }

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["176.25.98.118/32"]
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["176.25.98.118/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ob1-SecurityGroup1"
  }
}

#Reference the template file that will be used to configure the Juice Shop application
data "template_file" "user_data1" {
  template = "${file("${path.module}/userdata.tmpl")}"

}

#Build the Juice shop EC2 instance and install the Juice shop application
resource "aws_instance" "OB1-JuiceShop" {
  ami = "ami-0765d48d7e15beb93"
  instance_type = "t2.micro"
  subnet_id   = module.vpc.public_subnets[0]
  private_ip = "10.0.1.10"
  key_name   = "${var.ssh_key_name}"
  user_data = "${data.template_file.user_data1.rendered}"
  security_groups = [ aws_security_group.f5.id ]
    tags = {
    Name = "OB1-JuiceShop"
  }
}

#Reference the template file that will be used to configure the JNGINX APP Protect
data "template_file" "user_data2" {
  template = "${file("${path.module}/userdata-nap.tmpl")}"

}

#Build the NGINX APP Protect EC2 instance and configure NAP
resource "aws_instance" "OB1-NAP" {
  ami = "ami-067ec6724e2ff931d"
  instance_type = "t3.small"
  subnet_id   = module.vpc.public_subnets[0]
  private_ip = "10.0.1.11"
  key_name   = "${var.ssh_key_name}"
  user_data = "${data.template_file.user_data2.rendered}"
  security_groups = [ aws_security_group.f5.id ]
    tags = {
    Name = "OB1-NAP"
  }
}

#Output the direct route to Juice Shop & NAP protected route to Juice Shop
output "NAP_pub_ip" {
  value = "http://${aws_instance.OB1-NAP.public_ip}"
}

output "JuiceShop_pub_ip" {
  value = "http://${aws_instance.OB1-JuiceShop.public_ip}"
}