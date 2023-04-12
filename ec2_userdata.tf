data "template_file" "user_data" {
  template = <<-EOF
#!/bin/bash
systemctl stop ProductManager.service

echo "server.port=8080" > /opt/app/application.properties
echo "spring.datasource.url=jdbc:mariadb://${aws_db_instance.db_instance.address}:${aws_db_instance.db_instance.port}/csye6225" >> /opt/app/application.properties
echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MariaDB103Dialect" >> /opt/app/application.properties
echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/app/application.properties
echo "spring.datasource.username=${aws_db_instance.db_instance.username}" >> /opt/app/application.properties
echo "spring.datasource.password=${aws_db_instance.db_instance.password}" >> /opt/app/application.properties
echo "spring.datasource.driver-class-name=org.mariadb.jdbc.Driver" >> /opt/app/application.properties

sudo chown -R ec2-user:ec2-user /opt/app
sudo chmod -R 755 /opt/app

systemctl start ProductManager.service
systemctl enable ProductManager.service
EOF
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

# Create the EC2 instance
resource "aws_instance" "my_ec2_instance" {
  for_each = { for idx, subnet in aws_subnet.public_subnet : idx => subnet }

  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  subnet_id              = aws_subnet.public_subnet[each.key].id
  key_name               = var.key_pair_name

  # Disable termination protection
  #  disable_api_termination = true

  # Define the root volume with size and type
  root_block_device {
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = data.template_file.user_data.rendered
}