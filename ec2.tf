data "template_file" "user_data" {
  template = <<-EOF
              #!/bin/bash
              export DB_HOSTNAME=${aws_db_instance.db_instance.endpoint}
              export DB_USERNAME=csye6225
              export DB_PASSWORD=password
              export S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}

              echo "spring.jpa.hibernate.ddl-auto=update" > /opt/app/application.properties
              echo "spring.datasource.url=jdbc:mysql://${aws_db_instance.db_instance.endpoint}/db_example" >> /opt/app/application.properties

              chown -R $USER:$USER  /opt/app/application.properties


# Move code to GitHub action in webapp
              # Install required software, clone your application code from Git, etc.
              # sudo yum update -y
              # sudo yum install -y maven

              # Build the application
              cd ./ProductManager
              mvn install # mvn assemble or package
# Move above code to GitHub actions

# Move below code to Packer template (shell provisioner)
              # Move the JAR file to deployment directory
              sudo yum update -y
              sudo mkdir /opt/app

# Move below code to Packer (file provisioner)
              sudo cp ./ProductManager/target/ProductManager-0.0.1-SNAPSHOT.jar /opt/app/
              sudo cp ./scripts/ProductManager.service /etc/systemd/system/

# Move below code to Packer template (shell provisioner)
              sudo chown -R $USER:$USER /opt/app
              # Create systemd service file
              sudo systemctl daemon-reload
              sudo systemctl enable ProductManager.service
              # sudo systemctl start ProductManager.service
              # sudo systemctl status ProductManager.service
# Move above code to Packer
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