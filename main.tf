resource "aws_vpc" "main" {                # Creating VPC here
  cidr_block       = var.vpc_cidr_block     # Defining the CIDR block use 10.0.0.0/24 for demo
  instance_tenancy = var.vpc_instance_tenancy
#  tag {} tag everything that can be tagged.

  tags = {
    Name = "ecs_tf_qa_main"
    Stack = "Qa"
  }
}

resource "aws_internet_gateway" "igw" {    # Creating Internet Gateway
  vpc_id =  aws_vpc.main.id               # vpc_id will be generated after we create VPC

  tags = {
    Name = "ecs_tf_qa_igw]"
    Stack = "Qa"
  }
}

# Creating the NAT Gateway using subnet_id and allocation_id
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id = aws_subnet.private_subnet_1.id

  tags = {
    Name = "ecs_tf_qa_nat_gw_1"
    Stack = "Qa"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id = aws_subnet.private_subnet_2.id

  tags = {
    Name = "ecs_tf_qa_nat_gw_2"
    Stack = "Qa"
  }
}

resource "aws_eip" "nat_eip_1" {
  vpc   = true

  tags = {
    Name = "ecs_tf_qa_nat_eip_1"
    Stack = "Qa"
  }
}

resource "aws_eip" "nat_eip_2" {
  vpc   = true

  tags = {
    Name = "ecs_tf_qa_nat_eip_2"
    Stack = "Qa"
  }
}

resource "aws_subnet" "public_subnet" {    # Creating Public Subnets
  vpc_id =  aws_vpc.main.id
  cidr_block = var.public_subnet_cidr        # CIDR block of public subnets

  tags = {
    Name = "ecs_tf_qa_public_subnet]"
    Stack = "Qa"
  }
}

# Creating Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id =  aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_1          # CIDR block of private subnets

  tags = {
    Name = "ecs_tf_qa_private_subnet_1"
    Stack = "Qa"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_2

  tags = {
    Name = "ecs_tf_qa_private_subnet_2"
    Stack = "Qa"
  }
}

resource "aws_route_table" "public_rt" {
  # Creating RT for Public Subnet
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = var.public_subnet_cidr               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ecs_tf_qa_public_rt]"
    Stack = "Qa"
  }
}

resource "aws_route_table" "private_rt_1" {
  # Creating RT for Private Subnet
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = var.private_subnet_cidr_1            # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "ecs_tf_qa_private_rt_1"
    Stack = "Qa"
  }
}

resource "aws_route_table" "private_rt_2" {
  # Creating RT for Private Subnet
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = var.private_subnet_cidr_2            # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "ecs_tf_qa_private_rt_2"
    Stack = "Qa"
  }
}

# Route table Association with Public Subnet's
resource "aws_route_table_association" "public_rt_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Route table Association with Private Subnet's
resource "aws_route_table_association" "private_rt_association_1" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_rt_association_2" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

// SG to only allow SSH connections from VPC public subnets
resource "aws_security_group" "allow_web_ssh_private" {
  name        = "allow_web_ssh_private"
  description = "Allow Web and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH only from internal VPC clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Web only from internal VPC clients"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_tf_qa_allow_web_ssh_private]"
    Stack = "Qa"
  }
}

resource "aws_instance" "ec2_private_1" {
  ami                         = var.ec2_ami
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  subnet_id                   = var.private_subnet_cidr_1
  vpc_security_group_ids      = [aws_security_group.allow_web_ssh_private.id]

  tags = {
    Name  = "ecs_tf_qa_ec2_private_1"
    Stack = "Qa"
  }
}

# Configure the EC2 instance in a private subnet
resource "aws_instance" "ec2_private_2" {
  ami                         = var.ec2_ami
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  subnet_id                   = var.private_subnet_cidr_2
  vpc_security_group_ids      = [aws_security_group.allow_web_ssh_private.id]

  tags = {
    Name  = "ecs_tf_qa_ec2_private_2"
    Stack = "Qa"
  }
}

resource "aws_lb" "main_app_lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web_ssh_private.id]
  subnets            = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "main_tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# add ec2 instance in the private subnets (ami), application load balancer,target group,
# security group (port 80, 22)