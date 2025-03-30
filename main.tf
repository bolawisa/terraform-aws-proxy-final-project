# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "main-vpc" }
}

# Subnets
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-az1" }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-az2" }
}

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "private-az1" }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "private-az2" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id
  tags          = { Name = "nat-gateway" }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# AMI Data Source for Amazon Linux 2
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "web-sg" }
}

# EC2 Instances
# Nginx Proxy 1 in Public Subnet (AZ1)
resource "aws_instance" "nginx_proxy_1" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_az1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = "my-new-key"

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "echo 'OK' | sudo tee /usr/share/nginx/html/health.html",
      "echo 'server { listen 80; location / { proxy_pass http://${aws_lb.private_lb.dns_name}; proxy_set_header Host $$host; proxy_set_header X-Real-IP $$remote_addr; proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $$scheme; } }' | sudo tee /etc/nginx/conf.d/proxy.conf",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/bola/terraform/project/modules/infrastructure/my-new-key.pem")
      host        = self.public_ip
      timeout     = "5m"
    }
  }
  provisioner "local-exec" {
    command = "echo 'public-ip1 ${self.public_ip}' >> /home/bola/terraform/project/all-ips.txt"
  }
  tags = { Name = "nginx-proxy-1" }
}

# Nginx Proxy 2 in Public Subnet (AZ2)
resource "aws_instance" "nginx_proxy_2" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_az2.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = "my-new-key"

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "echo 'OK' | sudo tee /usr/share/nginx/html/health.html",
      "echo 'server { listen 80; location / { proxy_pass http://${aws_lb.private_lb.dns_name}; proxy_set_header Host $$host; proxy_set_header X-Real-IP $$remote_addr; proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $$scheme; } }' | sudo tee /etc/nginx/conf.d/proxy.conf",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/bola/terraform/project/modules/infrastructure/my-new-key.pem")
      host        = self.public_ip
      timeout     = "5m"
    }
  }
  provisioner "local-exec" {
    command = "echo 'public-ip2 ${self.public_ip}' >> /home/bola/terraform/project/all-ips.txt"
  }
  tags = { Name = "nginx-proxy-2" }
}

# Apache Web Server in Private Subnet (AZ1)
resource "aws_instance" "apache_az1" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_az1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my-new-key"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              echo 'Hello from AZ1' > /var/www/html/index.html
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  tags = { Name = "apache-az1" }
}

# Apache Web Server in Private Subnet (AZ2)
resource "aws_instance" "apache_az2" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_az2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my-new-key"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              echo 'Hello from AZ2' > /var/www/html/index.html
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  tags = { Name = "apache-az2" }
}

# Load Balancers
# Public Load Balancer
resource "aws_lb" "public_lb" {
  name               = "public-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
  security_groups    = [aws_security_group.web_sg.id]
  tags               = { Name = "public-lb" }
}

resource "aws_lb_target_group" "public_tg" {
  name     = "public-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/health.html"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }
}

resource "aws_lb_target_group_attachment" "nginx_proxy_1" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.nginx_proxy_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "nginx_proxy_2" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.nginx_proxy_2.id
  port             = 80
}

resource "aws_lb_listener" "public_lb_listener" {
  load_balancer_arn = aws_lb.public_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

# Private Load Balancer
resource "aws_lb" "private_lb" {
  name               = "private-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  security_groups    = [aws_security_group.web_sg.id]
  tags               = { Name = "private-lb" }
}

resource "aws_lb_target_group" "private_tg" {
  name     = "private-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/index.html"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }
}

resource "aws_lb_target_group_attachment" "apache_az1" {
  target_group_arn = aws_lb_target_group.private_tg.arn
  target_id        = aws_instance.apache_az1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "apache_az2" {
  target_group_arn = aws_lb_target_group.private_tg.arn
  target_id        = aws_instance.apache_az2.id
  port             = 80
}

resource "aws_lb_listener" "private_lb_listener" {
  load_balancer_arn = aws_lb.private_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_tg.arn
  }
}