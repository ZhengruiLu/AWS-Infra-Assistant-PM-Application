#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id
  name    = data.aws_route53_zone.existing_zone.name
  type    = "A"
  #  ttl     = 60
  #  records = [aws_eip.eip[0].public_ip]
  #  depends_on = [
  #    aws_eip.eip
  #  ]

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

data "aws_route53_zone" "existing_zone" {
  name = var.zone_name
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
#resource "aws_eip" "eip" {
#  #  instance = aws_instance.my_ec2_instance[0].id
#
#  count = 1
#
#  tags = {
#    Name = "my-eip-0"
#  }
#}

output "domain_url" {
  value = "http://${aws_lb.lb.dns_name}:${var.port}/"
}
