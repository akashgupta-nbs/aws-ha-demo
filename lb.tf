resource "aws_security_group" "load_balancer" {
  name        = "terraform_alb_security_group_new"
  description = "Terraform load balancer security group"
  vpc_id      = var.vpc-id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sky-ag-tf-demo-alb-security-group"
  }
}

resource "aws_lb" "alb" {
  name            = "sky-ag-tf-demo-alb"
  load_balancer_type = "application"
  security_groups = [aws_security_group.load_balancer.id]
  subnets         = var.subnet-ids
  tags = {
    Name = "sky-ag-tf-demo-alb"
  }
}

resource "aws_alb_target_group" "group" {
  name     = "sky-ag-tf-demo-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc-id

  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}