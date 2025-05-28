data "aws_ami" "ubuntu_22_04_lts" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu_22_04_lts.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.arm_ec2_access_key.key_name
  subnet_id                   = aws_subnet.arm_subnet_public.id
  vpc_security_group_ids      = [aws_security_group.arm_security_group.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2

              a2enmod proxy proxy_http
              cat <<EOT > /etc/apache2/sites-available/www.conf
              <VirtualHost *:80>
                RewriteEngine On
                RewriteRule ^/$ http://localhost:3000/nekretnine.html [P,L]
                ProxyPass / http://localhost:3000/
                ProxyPassReverse / http://localhost:3000/
                ErrorLog /var/log/apache2/error.log
                CustomLog /var/log/apache2/access.log combined
                ProxyPreserveHost On
              </VirtualHost>
              EOT
              a2ensite www.conf
              a2dissite 000-default.conf
              systemctl reload apache2
              systemctl enable apache2
EOF
}
