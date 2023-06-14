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