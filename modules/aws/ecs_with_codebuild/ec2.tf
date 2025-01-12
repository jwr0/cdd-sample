data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "production" {
  count = var.launch_production_ec2_instance ? 1 : 0
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2_servers.id]

  user_data_replace_on_change = true
  user_data = <<EOF
#!/bin/bash
set -x
# Redirect output to the console. https://repost.aws/knowledge-center/ec2-linux-log-user-data
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo Here is the response from the web-to-pdf internal service...
curl -k https://${aws_lb.web_to_pdf_internal.dns_name}
echo Response code was $?

echo Here is the response from the svg-to-pdf internal service...
curl -k https://${aws_lb.svg_to_pdf_internal.dns_name}
echo Response code was $?
EOF

  tags = {
    Name = "${var.environment_name} Production Server"
  }
}