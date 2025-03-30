# Outputs for Nginx Proxy Instances
output "nginx_proxy_1_public_ip" {
  value = aws_instance.nginx_proxy_1.public_ip
}

output "nginx_proxy_2_public_ip" {
  value = aws_instance.nginx_proxy_2.public_ip
}

# Outputs for Apache Web Servers
output "apache_az1_private_ip" {
  value = aws_instance.apache_az1.private_ip
}

output "apache_az2_private_ip" {
  value = aws_instance.apache_az2.private_ip
}

# Outputs for Load Balancers
output "public_lb_dns_name" {
  value = aws_lb.public_lb.dns_name
}

output "private_lb_dns_name" {
  value = aws_lb.private_lb.dns_name
}