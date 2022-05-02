# 런치 템플릿, 오토 스케일링 그룹, alb

resource "aws_launch_template" "bastion_host_template" {
  image_id      = "ami-02e05347a68e9c76f"
  instance_type = "t3.small"
  key_name      = aws_key_pair.app_server_key.key_name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion_host_template"
  }

  depends_on = [
    aws_security_group.bastion_sg
  ]
}

resource "aws_autoscaling_group" "bastion_host_asg" {
  health_check_type = "ELB"

  vpc_zone_identifier = module.app_vpc.public_subnets
  min_size            = 1
  max_size            = 3

  launch_template {
    id = aws_launch_template.bastion_host_template.id
  }
}

resource "aws_autoscaling_policy" "bastion_host_asg_policy" {
  name                   = "bastion_host_asg_policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.bastion_host_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 40.0
  }
}

resource "aws_lb" "bastion_host_alb" {
  name               = "bastion-host-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.app_vpc.public_subnets
}

resource "aws_lb_listener" "bastion_host_alb_listener" {
  load_balancer_arn = aws_lb.bastion_host_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.bastion_host_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "bastion_host_target_group" {
  name     = "bastion-host-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.app_vpc.vpc_id

  health_check {
    port     = "traffic-port"
    protocol = "HTTP"
    path     = "/wordpress"
  }
}

resource "aws_lb_target_group_attachment" "bastion_host_target_group_attachment" {
  count = 1

  port             = 80
  target_group_arn = aws_lb_target_group.bastion_host_target_group.arn
  target_id        = element(data.aws_instances.bastion_host_instances.ids, count.index)
  depends_on       = [data.aws_instances.bastion_host_instances]
}

data "aws_instances" "bastion_host_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.bastion_host_asg.name
  }
  depends_on = [aws_launch_template.bastion_host_template]
}