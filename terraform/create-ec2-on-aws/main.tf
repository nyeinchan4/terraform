#create EC2 with new vpc on aws

#defined provider

provider "aws" {
    region = "us-east-1"
}

#defined variable

variable vpc_cider_block {}
variable subnet_cider_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}

#create vpc

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cider_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

#create subnet-1 in vpc

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cider_block
    availability_zone = var.avail_zone
    tags = {
      Name: "${var.env_prefix}-subnet-1"
    }
}

#create gateway

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name : "${var.env_prefix}-igw"
    }
}

#route-table attach gateway

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name : "${var.env_prefix}-rtb"

    }
}

#route-table association with subnet-1

resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

#create security-group and open inbound port 22 and outbound port any

resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name : "${var.env_prefix}-sg"

    }
}

#get ami aws_image latest id form aws

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#create EC2

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = aws_security_group.myapp-sg.id
    availability_zone = var.avail_zone

    associate_public_ip_address = true

    key_name = "ec2-key"

    tags = {
        Name : "${var.env_prefix}-myapp-server"
    }
}

