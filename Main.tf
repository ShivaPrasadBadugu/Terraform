terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "demo-server" {
    ami = "ami-0287a05f0ef0e9d9a"
    instance_type = "t2.micro"
    key_name = "Mykeypair"
    vpc_security_group_ids = [aws_security_group.demo-sg.id]
    subnet_id = aws_subnet.demo-public-subnet-01.id
    for_each = toset([ "jenkins-master","build-slave","ansible" ])
    tags = {
      Name = "${each.key}"
    }
}

resource "aws_security_group" "demo-sg" {
    name = "demo-sg"
    description = "SSH Access"
    vpc_id = aws_vpc.demo-vpc.id

    ingress {
    description      = "SSH Access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
  
}

resource "aws_vpc" "demo-vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
        name = "demo-vpc"
    }
}

resource "aws_subnet" "demo-public-subnet-01" {
    vpc_id = aws_vpc.demo-vpc.id
    cidr_block = "10.1.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"
    tags = {
      "name" = "demo-public-subnet-01" 
    }
}

resource "aws_subnet" "demo-public-subnet-02" {
    vpc_id = aws_vpc.demo-vpc.id
    cidr_block = "10.1.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1b"
    tags = {
      "name" = "demo-public-subnet-02" 
    }
}

resource "aws_internet_gateway" "demo-IGW" {
    vpc_id = aws_vpc.demo-vpc.id
    tags = {
      Name = "demo-IGW"
    }
  
}

resource "aws_route_table" "demo-public-rt" {
  vpc_id = aws_vpc.demo-vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-IGW.id
  }
}

resource "aws_route_table_association" "demo-rta-public-subnet-01" {
    subnet_id = aws_subnet.demo-public-subnet-01.id
    route_table_id = aws_route_table.demo-public-rt.id
}

resource "aws_route_table_association" "demo-rta-public-subnet-02" {
    subnet_id = aws_subnet.demo-public-subnet-02.id
    route_table_id = aws_route_table.demo-public-rt.id
}

