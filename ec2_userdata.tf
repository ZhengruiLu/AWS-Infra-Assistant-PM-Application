data "template_file" "user_data" {
  template = <<-EOF
              #!/bin/bash

              echo "" > /opt/app/application.properties

              echo "spring.jpa.hibernate.ddl-auto=update" > /opt/app/application.properties
              echo "spring.datasource.url=jdbc:mysql://${aws_db_instance.db_instance.endpoint}:3306/csye6225" >> /opt/app/application.properties

              chown -R $USER:$USER  /opt/app/application.properties

              sudo systemctl restart ProductManager.service
              EOF
}

# Create the EC2 instance
resource "aws_instance" "my_ec2_instance" {
  for_each = { for idx, subnet in aws_subnet.public_subnet : idx => subnet }

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