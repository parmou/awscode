##################################################################################
# RESOURCES Launch Template
##################################################################################

variable "environment_tag"{
    type = string
    default = "dev"
}

#-------------------------------------------------------------------------- // Launch Template Security Group
resource "aws_security_group" "troc_sg_lt" {
  name        = "${var.environment_tag}_troc"
  description = "Allow ports for troc"
  vpc_id      = "vpc-8fbbc9f2"

  #Allow HTTP from anywhere
  ingress {
    description = "allow for InBound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  #allow all outbound
  egress {
    description = "allow for OutBound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#-------------------------------------------------------------------------- // Launch Template
resource "aws_launch_template" "troc_lt" {
  name                   = "${var.environment_tag}_trocLt"
  image_id               = "ami-0c4fadedc2990b966"
  instance_type          = var.instance_size
  vpc_security_group_ids = [aws_security_group.troc_sg_lt.id]
  update_default_version = true

  iam_instance_profile {
    name = "sreSkywaker"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = "60"
      volume_type           = var.volume_type
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

  }
}


##################################################################################
# RESOURCES ALB TG
##################################################################################
#-------------------------------------------------------------------------- // ALB Security Group
resource "aws_security_group" "troc_sg_alb" {
  name        = "${var.environment_tag}_troc_alb"
  description = "Allow ports for troc"
  vpc_id      = "vpc-8fbbc9f2"

  #Allow HTTP from anywhere
  ingress {
    description = "allow for InBound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  #allow all outbound
  egress {
    description = "allow for OutBound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#-------------------------------------------------------------------------- // ALB
resource "aws_lb" "trocAlb" {
  name               = "${var.environment_tag}trocAlb"
  internal           = true
  load_balancer_type = "application"
  subnets            = tolist(data.aws_subnet_ids.rtdd_subnets_stage.ids)
  security_groups    = [aws_security_group.troc_sg_alb.id]

  //enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}


resource "aws_lb_target_group" "trocTG" {
  name     = "${var.environment_tag}trocAlbTG"
  port     = 19999
  protocol = "HTTP"
  vpc_id   = "vpc-8fbbc9f2"
  target_type          = "instance"
  deregistration_delay = 120
  health_check {
        enabled             = true
        interval            = 10
        path                = "/"
  //      port                = 4001
        healthy_threshold   = 10
        unhealthy_threshold = 10
        timeout  = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
}

resource "aws_lb_target_group" "trocAlbCanaryTG" {
  name     = "${var.environment_tag}trocAlbCanaryTG"
  port     = 19999
  protocol = "HTTP"
  vpc_id   = "vpc-8fbbc9f2"
  target_type          = "instance"
  deregistration_delay = 120
  health_check {
        enabled             = true
        interval            = 10
        path                = "/"
  //      port                = 4001
        healthy_threshold   = 10
        unhealthy_threshold = 10
        timeout  = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
}

resource "aws_lb_listener" "trocAlb_listener" {
load_balancer_arn = aws_lb.trocAlb.arn
  port              = "80"
  protocol          = "HTTP"

   default_action {    
    target_group_arn = aws_lb_target_group.trocTG.arn
    type             = "forward"
  }

}

resource "aws_lb_listener_rule" "host_based_routing" {
  listener_arn = aws_lb_listener.trocAlb_listener.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      

      target_group {
        arn    = aws_lb_target_group.trocAlbCanaryTG.arn
        weight = 80
      }

      target_group {
        arn    = aws_lb_target_group.trocAlbCanaryTG.arn
        weight = 20
      }

      stickiness {
        enabled  = false
        duration = 0
      }
    }
  }
}
##################################################################################
# RESOURCES AutoScaling Group
##################################################################################

#-------------------------------------------------------------------------- // ASG
resource "aws_autoscaling_group" "troc_asg" {
  name              = "${var.environment_tag}_troc_asg"
  desired_capacity  = 0
  max_size          = 0
  min_size          = 0
  health_check_type = "ELB"
  //  force_delete        = true
  //termination_policies = ["OldestInstance"]
  vpc_zone_identifier = tolist(data.aws_subnet_ids.rtdd_subnets_stage.ids)
  target_group_arns   = [aws_lb_target_group.trocTG]
  //target_group_arns   = ["arn:aws:elasticloadbalancing:ap-south-1:304016915943:targetgroup/rtddtrocAlbTG/b977f8fab18a61d0"] 

  launch_template {
    id      = aws_launch_template.troc_lt.id
    version = "$Latest"
  }
  depends_on = [aws_launch_template.troc_lt]
}

resource "aws_autoscaling_group" "troc_Canaryasg" {
  name              = "${var.environment_tag}_troc_Canaryasg"
  desired_capacity  = 0
  max_size          = 0
  min_size          = 0
  health_check_type = "ELB"
  //  force_delete        = true
  //termination_policies = ["OldestInstance"]
  vpc_zone_identifier = tolist(data.aws_subnet_ids.rtdd_subnets_stage.ids)
  target_group_arns   = [aws_lb_target_group.trocAlbCanaryTG]
  //  target_group_arns   = "arn:aws:elasticloadbalancing:ap-south-1:304016915943:targetgroup/rtddtrocAlbCanaryTG/b586f451ab91f18e"

  launch_template {
    id      = aws_launch_template.troc_lt.id
    version = "$Latest"
  }
  depends_on = [aws_launch_template.troc_lt]
}
