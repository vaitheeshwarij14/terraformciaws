provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Security group for Bastion Host"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion_host" {
  ami             = "ami-05f0fbedc4d90181d"  # Specify the appropriate AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  security_group  = [aws_security_group.bastion_sg.id]
  key_name        = "terraform_key_pair"     # Replace with your key pair name

  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_instance" "private_instance" {
  ami             = "ami-05f0fbedc4d90181d"  # Specify the appropriate AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private.id
  key_name        = "terraform_key_pair"     # Replace with your key pair name

  tags = {
    Name = "Private Instance"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc.main.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  associate_subnet_ids = [aws_subnet.private.id]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
