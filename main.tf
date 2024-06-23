provider "aws" {
  region = "us-west-1"
}

# Create a new VPC
resource "aws_vpc" "fortisandbox_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "FortiSandboxVPC"
  }
}

# Create a public subnet
resource "aws_subnet" "fortisandbox_subnet" {
  vpc_id            = aws_vpc.fortisandbox_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "FortiSandboxSubnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "fortisandbox_igw" {
  vpc_id = aws_vpc.fortisandbox_vpc.id

  tags = {
    Name = "FortiSandboxIGW"
  }
}

# Create a route table
resource "aws_route_table" "fortisandbox_rt" {
  vpc_id = aws_vpc.fortisandbox_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fortisandbox_igw.id
  }

  tags = {
    Name = "FortiSandboxRouteTable"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "fortisandbox_rta" {
  subnet_id      = aws_subnet.fortisandbox_subnet.id
  route_table_id = aws_route_table.fortisandbox_rt.id
}

# Security group for FortiSandbox
resource "aws_security_group" "fortisandbox_sg" {
  vpc_id      = aws_vpc.fortisandbox_vpc.id
  name        = "fortisandbox_sg"
  description = "Allow necessary traffic to FortiSandbox"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "FortiSandboxSG"
  }
}

# Launch FortiSandbox EC2 instance from the Marketplace AMI
resource "aws_instance" "fortisandbox" {
  ami           = "ami-0c1cc2987bf591a2b"  # Replace with the actual AMI ID from the Marketplace. US-West-1 FSB v4.4.6
  instance_type = "c5.xlarge"            # Choose an appropriate instance type
  key_name      = "fsb-access-key-west1"         # Replace with your key pair name

  tags = {
    Name = "FortiSandbox"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Any user data script to initialize FortiSandbox
  EOF

  # Ensure the instance has a public IP if necessary
  associate_public_ip_address = true

  # Define security group to allow necessary traffic
  vpc_security_group_ids = [aws_security_group.fortisandbox_sg.id]

  # Use the new subnet created
  subnet_id = aws_subnet.fortisandbox_subnet.id
}
