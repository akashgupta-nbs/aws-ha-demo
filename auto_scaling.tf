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

  image_id = var.image-id # Amazon ubuntu 
  instance_type = var.instance-type
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

  min_size             = var.min-size
  desired_capacity     = var.desire-cap
  max_size             = var.max-size
  
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