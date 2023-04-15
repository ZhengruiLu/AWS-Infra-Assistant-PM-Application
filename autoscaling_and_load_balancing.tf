# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
#Launch Configuration
#Key	Value
#ImageId	Your custom AMI
#Instance Type	t2.micro
#KeyName	YOUR_AWS_KEYNAME
#AssociatePublicIpAddress	True
#UserData	SAME_USER_DATA_AS_CURRENT_EC2_INSTANCE
#IAM Role	SAME_AS_CURRENT_EC2_INSTANCE
#Resource Name	asg_launch_config
#Security Group	WebAppSecurityGroup
resource "aws_launch_template" "asg_launch_config" {
  name          = "asg_launch_config"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_security_group.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 8
      volume_type           = "gp2"
    }
  }

  user_data = base64encode(data.template_file.user_data.rendered)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
#Note: You should add tags Links to an external site.(AutoScalingGroup TagPropertyLinks to an external site.) to the EC2 instances in your Auto Scaling Group.
#Parameter	Value
#Cooldown	60
#LaunchConfigurationName	asg_launch_config
#MinSize	1
#MaxSize	3
#DesiredCapacity	1
resource "aws_autoscaling_group" "asg" {
  name = "csye6225-asg-spring2023"

  default_cooldown = 60
  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = [for subnet in aws_subnet.public_subnet : subnet.id]

  tag {
    key                 = "CSYE6225"
    value               = "CSYE6225"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.asg_launch_config.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.alb_tg.arn
  ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy
#resource "aws_autoscaling_policy" "asg_cpu_policy" {
#  name = "csye6225-asg-cpu"
#  autoscaling_group_name = aws_autoscaling_group.asg.name
#  adjustment_type = "ChangeInCapacity"
#  policy_type = "TargetTrackingScaling"
#
#  # CPU Utilization is above 40%
#  target_tracking_configuration {
#    predefined_metric_specification {
#      predefined_metric_type = "ASGAverageCPUUtilization"
#    }
#    target_value = 40.0
#  }
#}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "csye6225-scale-up-policy"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scale-up" {
  alarm_name          = "csye6225-cpu-alarm1"
  alarm_description   = "csye6225-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "csye6225-scale-down-policy"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scale-down" {
  alarm_name          = "csye6225-cpu-alarm2"
  alarm_description   = "csye6225-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
#EC2 instances launched in the auto-scaling group should now be load balanced.
#Add a balancer resource to your Terraform template.
#Set up an Application load balancer to accept HTTP traffic on port 80 and forward it to your application instances on whatever port it listens on.
#You are not required to support HTTP to HTTPS redirection.
#Attach the load balancer security group to the load balancer.
resource "aws_lb" "lb" {
  name               = "csye6225-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.lb_security_group.id]
  subnets         = [for subnet in aws_subnet.public_subnet : subnet.id]

  tags = {
    Application = "WebApp"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "alb_tg" {
  name        = "csye6225-lb-alb-tg"
  target_type = "instance"

  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path     = "/healthz"
    protocol = "HTTP"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  #  ssl_policy        = "ELBSecurityPolicy-2016-08"
  #  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}
