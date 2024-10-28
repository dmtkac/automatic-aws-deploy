resource "aws_instance" "web_app_instance" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.aws_key_pair_name
  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  subnet_id              = element(data.aws_subnets.public.ids, count.index)

  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name  

  user_data = <<-EOF
              #!/bin/bash

              exec > /var/log/user-data.log 2>&1
              nohup /home/ubuntu/install.sh &
              EOF

  tags = {
    Name = "web-app-instance-${count.index}"
  }

  depends_on = [aws_iam_instance_profile.ec2_instance_profile]
}