resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id
  name    = data.aws_route53_zone.existing_zone.name
  type    = "A"
  ttl     = 60
  records = [aws_eip.eip[0].public_ip]
  depends_on = [
    aws_eip.eip
  ]
}

data "aws_route53_zone" "existing_zone" {
  name = var.zone_name
}


resource "aws_eip" "eip" {
  instance = aws_instance.my_ec2_instance[0].id

  count = 1

  tags = {
    Name = "my-eip-0"
  }
}

output "domain_url" {
  value = "http://${var.zone_name}:${var.port}/"
}
