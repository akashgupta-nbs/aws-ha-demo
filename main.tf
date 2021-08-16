
provider "aws" {
  region                  = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "sky-ha-dev-demo"
    versioning {
        enabled = true
    }
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
    object_lock_configuration {
        object_lock_enabled = "Enabled"
    }
    tags = {
        Name = "S3 Remote Terraform State Store"
    }
}

variable "vpc-id" {
  type        = string
  default = "vpc-f8a10b85"
}
variable "subnet-ids" {
  type        = list(string)
  default = ["subnet-5e2b4f7f","subnet-8260fbdd"]
}



variable "cidr-blocks" {
  type        = list
  default = ["0.0.0.0/0"]
}

resource "aws_dynamodb_table" "terraform-lock" {
    name           = "terraform_state"
    read_capacity  = 5
    write_capacity = 5
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        "Name" = "DynamoDB Terraform State Lock Table"
    }
}

terraform {
  backend "s3" {
    bucket         = "sky-ha-dev-demo"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_state"
  }
}


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

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = var.vpc-id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}


resource "aws_launch_configuration" "web" {
  name_prefix = "web-test"

  image_id = "ami-09e67e426f25ce0d7" # Amazon ubuntu 
  instance_type = "t2.micro"
  key_name = "myawskey"

  security_groups = [ aws_security_group.allow_http.id ]
  associate_public_ip_address = true

  user_data = <<USER_DATA
#!/bin/bash
sudo su -
apt update
apt install nginx -y
apt install jq -y
apt install docker.io
echo "Server Info: $(curl http://169.254.169.254/latest/meta-data/local-ipv4)" >> /var/www/html/index.nginx-debian.html

  USER_DATA

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size             = 1
  desired_capacity     = 1
  max_size             = 1
  
  health_check_type    = "ELB"
  # load_balancers = [
  #   aws_alb.load_balancer.id
  # ]
  #target_group_arns = [aws_lb.alb.arn]
  target_group_arns = ["arn:aws:elasticloadbalancing:us-east-1:454661681615:targetgroup/sky-ag-tf-demo-alb-target/f60fc7424a662934"]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

 vpc_zone_identifier  = var.subnet-ids

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

    tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }

}