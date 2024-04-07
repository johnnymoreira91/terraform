terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_dev"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "dev_public_subnet"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_route_table" "dev_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "dev_route_table_rt"
  }
}

resource "aws_route" "dev_routetointernet" {
  route_table_id            = aws_route_table.dev_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_pub_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.dev_route_table.id
}

resource "aws_instance" "app_server" {
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  key_name = "key-personal"
  user_data = <<-EOF
                  #!/bin/bash
                  cd /home/ubuntu
                  echo "<h1>Pagina test</h1>" > index.html"
                  nohup busybox  httpd -f -p 8080 &
                 EOF

  tags = {
    Name = "ecs_terraform"
  }
}
