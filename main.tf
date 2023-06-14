############################################
# Provider
############################################

provider "aws" {
  region     = var.aws_region
}

############################################
# IAM
############################################

resource "aws_iam_role" "ssm_system_manager" {
  name = "ssm_management"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "role for simple system management"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_mgmt_attachment" {
  role       = aws_iam_role.ssm_system_manager.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core_attachment" {
  role       = aws_iam_role.ssm_system_manager.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "instance-profile"
  role = aws_iam_role.ssm_system_manager.name
  tags = {
    Name = "my_profile"
  }
}

############################################
# Security group
############################################

resource "aws_security_group" "allow_http_traffic" {
  name        = "allow_http_traffic"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["91.211.97.132/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_traffic"
  }
}

resource "aws_security_group" "allow_sec1" {
  name        = "allow_sec1"
  description = "Allow HTTP inbound traffic to load"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    description      = "Traffic from http_sec_group"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    security_groups = [aws_security_group.allow_http_traffic.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

############################################
# Network
############################################

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.16.0.0/16"
}

resource "aws_subnet" "subnet_1_public" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "public1")
  availability_zone = var.availability_zone_a
  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "subnet_2_public" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "public2")
  availability_zone = var.availability_zone_b
  tags = {
    Name = "public_subnet_2"
  }
}

resource "aws_subnet" "subnet_3_private" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "private1")
  availability_zone = var.availability_zone_a
  tags = {
    Name = "private_subnet_3"
  }
}

resource "aws_subnet" "subnet_4_private" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = lookup(var.cidr_ranges, "private2")
  availability_zone = var.availability_zone_b
  tags = {
    Name = "private_subnet_4"
  }
}

resource "aws_internet_gateway" "terraform_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id
}

resource "aws_eip" "terraform_elip" {
  domain = "vpc"
}

resource "aws_eip" "terraform_elip2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "terraform_nat" {
  allocation_id = aws_eip.terraform_elip.id
  subnet_id     = aws_subnet.subnet_1_public.id

  tags = {
    Name = "My_nat_1"
  }
}

resource "aws_nat_gateway" "terraform_nat2" {
  allocation_id = aws_eip.terraform_elip2.id
  subnet_id     = aws_subnet.subnet_2_public.id

  tags = {
    Name = "My_nat_2"
  }
}

resource "aws_route_table" "terraform_route_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gateway.id
  }
}

resource "aws_route_table" "route_nat" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_nat.id
  }
}

resource "aws_route_table" "route_nat2" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_nat2.id
  }
}

resource "aws_route_table_association" "terraform_associate1" {
  subnet_id      = aws_subnet.subnet_1_public.id
  route_table_id = aws_route_table.terraform_route_gateway.id
}

resource "aws_route_table_association" "terraform_associate2" {
  subnet_id      = aws_subnet.subnet_2_public.id
  route_table_id = aws_route_table.terraform_route_gateway.id
}

resource "aws_route_table_association" "terraform_associate3" {
  subnet_id      = aws_subnet.subnet_3_private.id
  route_table_id = aws_route_table.route_nat.id
}

resource "aws_route_table_association" "terraform_associate4" {
  subnet_id      = aws_subnet.subnet_4_private.id
  route_table_id = aws_route_table.route_nat2.id
}

############################################
# launch_configuration
############################################

resource "aws_launch_template" "machine_image_type" {
  name_prefix            = "terraform"
  image_id               = var.used_image
  instance_type          = var.instance_type
  update_default_version = true
  iam_instance_profile {
    name = aws_iam_instance_profile.iam_instance_profile.name
   }
  tags = {
      Name =  "launch_configuration_template"
  }

  vpc_security_group_ids = [aws_security_group.allow_sec1.id]

  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    amazon-linux-extras install -y nginx1
    systemctl enable nginx --now
    EOF
  )
}

resource "aws_autoscaling_group" "my_autoscaling_group" {
  name               = "my_autoscaling_group"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  vpc_zone_identifier = [aws_subnet.subnet_3_private.id, aws_subnet.subnet_4_private.id]
  target_group_arns = [ aws_lb_target_group.alb-target.arn ]
  launch_template {
    id      = aws_launch_template.machine_image_type.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "the_policy" {
  name                   = "autoscaling_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
}

resource "aws_cloudwatch_metric_alarm" "my_alarm" {
  alarm_name                = "CPU load check 80 or more"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "Cpu utilization threshold overload - adding another instance"
  alarm_actions = [aws_autoscaling_policy.the_policy.arn]
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.my_autoscaling_group.name
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_lb" {
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.id
  lb_target_group_arn = aws_lb_target_group.alb-target.arn
}

############################################
# load_balancer
############################################

resource "aws_lb" "load_balancer" {
  name               = "load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_traffic.id]
  subnets            = [aws_subnet.subnet_1_public.id, aws_subnet.subnet_2_public.id]

  enable_deletion_protection = false
  tags = {
    name = "exam-load-balancer"
  }
}

resource "aws_lb_target_group" "alb-target" {
  name        = "alb-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.terraform_vpc.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  tags = {
    Name = "load-balancer-listener"
  }
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target.arn
  }
}

############################################
# variables
############################################

variable "subnet_type" {
  default = {
    public  = "public"
    private = "private"
  }
}

variable "cidr_ranges" {
  default = {
    public1  = "172.16.1.0/24"
    public2  = "172.16.3.0/24"
    private1 = "172.16.4.0/24"
    private2 = "172.16.5.0/24"
  }
}

variable "instance_type" {
  default = "t2.micro"
  }

variable "used_image" {
  default = "ami-0e23c576dacf2e3df"
  }

variable "availability_zone_a" {
    type = string
    default = "eu-west-1a"
}

variable "availability_zone_b" {
    type = string
    default = "eu-west-1b"
}

variable "aws_region" {
  type        = string
  description = "The only region we should use"
  default     = "eu-west-1"
}
