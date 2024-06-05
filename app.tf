# configure the AWS provider
provider "aws" {
  region = "us-east-1"
}
# generating the ec2 instance
resource "aws_instance" "server" {
  ami                         = "ami-0d191299f2822b1fa"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids      = [aws_security_group.ec2-security-group.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -x
 sudo yum install git httpd -y
 sudo yum update -y
git clone https://github.com/cloudacademy/static-website-example.git
sudo cp -r static-website-example/* /var/www/html/
sudo systemctl start httpd
sudo systemctl enable httpd
echo "httpd installed successfully"
EOF


  tags = {
    Name = "jessica-server"
  }
}
# keypair code 
# Generate a secure key using a rsa algorithm
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
# creating the keypair in aws
resource "aws_key_pair" "ec2_key" {
  key_name   = "my-ec2-keypair"
  public_key = tls_private_key.ec2_key.public_key_openssh
}
# Save the .pem file locally for remote connection
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.ec2_key.key_name}.pem"
  content  = tls_private_key.ec2_key.private_key_pem
}
# create the security group to allow the ssh remote connection
# here the instance will be created in the default VPC
resource "aws_security_group" "ec2-security-group" {
  name        = "my-security-group"
  description = "Allow SSH inbound traffic"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Generating some output

output "instance_ip" {
  value = aws_instance.server.public_ip
}

output "dns_name" {
  value = aws_instance.server.public_dns
}

#output "vpcid" {
#  value = module.vpc.vpc_id
#}
