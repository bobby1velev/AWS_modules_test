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