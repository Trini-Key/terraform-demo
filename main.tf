resource "aws_vpc" "main" {                # Creating VPC here
  cidr_block       = var.vpc_cidr_block     # Defining the CIDR block use 10.0.0.0/24 for demo
  instance_tenancy = var.vpc_instance_tenancy

  tags = {
    Name = "ecs_tf_qa_main"
    Stack = "Qa"
  }
}

data "aws_vpc" "main" {
  id = aws_vpc.main.id
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
  subnet_id = aws_subnet.public_subnet_1.id

  tags = {
    Name = "ecs_tf_qa_nat_gw_1"
    Stack = "Qa"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id = aws_subnet.public_subnet_1.id

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

resource "aws_subnet" "public_subnet_1" {    # Creating Public Subnets
  vpc_id =  aws_vpc.main.id
  cidr_block = var.public_subnet_cidr_1        # CIDR block of public subnets
  availability_zone = var.availability_zone_3

  tags = {
    Name = "ecs_tf_qa_public_subnet]"
    Stack = "Qa"
  }
}

# Creating Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id =  aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_1 # CIDR block of private subnets
  availability_zone = var.availability_zone_1

  tags = {
    Name = "ecs_tf_qa_private_subnet_1"
    Stack = "Qa"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_2
  availability_zone = var.availability_zone_2

  tags = {
    Name = "ecs_tf_qa_private_subnet_2"
    Stack = "Qa"
  }
}
resource "aws_route_table" "public_rt_1" {
  # Creating RT for Public Subnet
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"              # Traffic from Public Subnet reaches Internet via Internet Gateway
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
    cidr_block     = "0.0.0.0/0"            # Traffic from Private Subnet reaches Internet via NAT Gateway
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
    cidr_block     = "0.0.0.0/0"           # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "ecs_tf_qa_private_rt_2"
    Stack = "Qa"
  }
}

# Route table Association with Public Subnet's
resource "aws_route_table_association" "public_rt_association_1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt_1.id
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

#  ingress {
#    description               = "app-instance-ingress"
#    from_port                 = 0
#    to_port                   = 0
#    protocol                  = "-1"
#    self                      = true
#  }

  ingress {
    description = "SSH only from internal VPC clients"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_public_sg.id]
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Web only from internal VPC clients"
    from_port   = var.web_port
    to_port     = var.web_port
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_public_sg.id]
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_tf_qa_allow_web_ssh_private"
    Stack = "Qa"
  }
}

resource "aws_security_group" "alb_public_sg" {
  name        = "allow_vpc_public"
  description = "allow alb inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH only from internal VPC clients"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Web only from internal VPC clients"
    from_port   = var.web_port
    to_port     = var.web_port
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
    Name = "ecs_tf_qa_alb_public_sg"
    Stack = "Qa"
  }
}

#resource "aws_instance" "ec2_private_1" {
#  ami                         = var.ec2_ami
#  associate_public_ip_address = true
#  instance_type               = "t2.micro"
#  subnet_id                   = aws_subnet.private_subnet_1.id
#  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
#  vpc_security_group_ids      = [aws_security_group.allow_web_ssh_private.id, aws_security_group.alb_public_sg.id]
#  user_data = <<-EOF
#              #!/bin/bash
#              yum update
#              yum install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm
#              sudo systemctl enable amazon-ssm-agent
#              sudo systemctl start amazon-ssm-agent
#              yum install -y httpd
#              systemctl start httpd
#              systemctl enable httpd
#              cd /var/www/html
#              echo "<html><body><h1>Deployed via Terraform</h1></body></html>">index.html
#              EOF
#
#  tags = {
#    Name  = "ecs_tf_qa_ec2_private_1"
#    Stack = "Qa"
#  }
#}
#
## Configure the EC2 instance in a private subnet
#resource "aws_instance" "ec2_private_2" {
#  ami                         = var.ec2_ami
#  associate_public_ip_address = true
#  instance_type               = "t2.micro"
#  subnet_id                   = aws_subnet.private_subnet_2.id #subnet ID not CIDR Block
#  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
#  vpc_security_group_ids      = [aws_security_group.allow_web_ssh_private.id]
#  user_data = <<-EOF
#              #!/bin/bash
#              yum update
#              yum install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm
#              sudo systemctl enable amazon-ssm-agent
#              sudo systemctl start amazon-ssm-agent
#              yum install -y httpd
#              systemctl start httpd
#              systemctl enable httpd
#              cd /var/www/html
#              echo "<html><body><h1>Deployed via Terraform</h1></body></html>">index.html
#              EOF
#
#  tags = {
#    Name  = "ecs_tf_qa_ec2_private_2"
#    Stack = "Qa"
#  }
#}

resource "aws_launch_configuration" "my_launch_config" {
  image_id = var.ec2_ami
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_web_ssh_private.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update
    yum install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    cd
    cd /var/www/html
    echo "<html><body><h1>Deployed via Terraform</h1></body></html>">index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main_app_lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_public_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main_app_lb.arn
  port              = var.web_port
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = "404"
    }
  }
}

resource "aws_lb_target_group" "main_tg" {
  name     = "tf-example-lb-tg"
  port     = var.web_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/index.html"
    port = 80
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.my_launch_config.name
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  target_group_arns = [aws_lb_target_group.main_tg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 4

  tag {
    key = "Name"
    value = "Terraform-asg"
    propagate_at_launch = true
  }
}

resource "aws_alb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.front_end.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_tg.arn
  }

  condition {
    path_pattern {
      values = ["/html/*"]
    }
  }
}

#resource "aws_lb_target_group_attachment" "test" {
#  target_group_arn = aws_lb_target_group.main_tg.arn
#  target_id        = aws_instance.ec2_private_1.id
#  port             = 80
#}
#
#resource "aws_lb_target_group_attachment" "test" {
#  target_group_arn = aws_lb_target_group.main_tg.arn
#  target_id        = aws_instance.ec2_private_2.id
#  port             = 80
#}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Principal": {"Service": "ssm.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
}
  EOF

  tags = {
    name = "ec2_ssm_role"
    description = "EC2 role for SSM for Quick-Setup"
  }
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_ssm_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_role_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile_proj"
  role = aws_iam_role.ec2_ssm_role.name
}