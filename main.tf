provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create an Internet Gateway and attach it to the VPC 
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create the first subnet in us-east-1a
resource "aws_subnet" "my_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create the second subnet in us-east-1b
resource "aws_subnet" "my_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Create a route table for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a route to allow internet access for public subnets
resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Associate the route table with the subnets
resource "aws_route_table_association" "subnet_1_route_association" {
  subnet_id      = aws_subnet.my_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "subnet_2_route_association" {
  subnet_id      = aws_subnet.my_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create an EC2 instance in the first subnet (us-east-1a)
resource "aws_instance" "my_ec2" {
  ami           = "ami-05576a079321f21f8"  # Replace with the latest Amazon Linux AMI ID for your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet_1.id  # Use the first subnet's ID

  vpc_security_group_ids = [aws_security_group.my_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y nginx
              echo "Hello, World!" > /usr/share/nginx/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
}

# Create a security group
resource "aws_security_group" "my_sg" {
  name        = "allow_http_traffic"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "my_lb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.my_sg.id]
  subnets            = [
    aws_subnet.my_subnet_1.id,
    aws_subnet.my_subnet_2.id
  ]
  enable_deletion_protection = false

  enable_cross_zone_load_balancing = true
 
}
