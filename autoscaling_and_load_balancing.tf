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
  image_id = var.ami_id
  instance_type = "t2.micro"
  key_name = var.key_pair_name

  network_interfaces {
    associate_public_ip_address = true
  }

  user_data = base64encode(data.template_file.user_data.rendered)
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
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
  min_size           = 1
  max_size           = 3
  desired_capacity   = 1

  tag {
    key = "Environment"
    value = "Production"
    propagate_at_launch = true
  }

  launch_template {
    id = aws_launch_template.asg_launch_config.id
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
#
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
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
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
  dimensions          = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
  actions_enabled = true
  alarm_actions       = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "csye6225-scale-down-policy"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
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
  dimensions          = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
  actions_enabled = true
  alarm_actions       = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb

resource "aws_lb" "lb" {

  name = "csye6225-lb"

  internal = false

  load_balancer_type = "application"

  ...

  tags = {

    Application = "WebApp"

  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group

resource "aws_lb_target_group" "alb_tg" {

  name = "csye6225-lb-alb-tg"

  target_type = "instance"

  ...

  health_check {

    ...

  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

resource "aws_lb_listener" "front_end" {

  ...

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.alb_tg.arn

  }

}