resource "aws_key_pair" "app_server_key" {
  key_name   = "app_server_key"
  public_key = file("/home/vagrant/.ssh/id_rsa.pub")
}

data "aws_ami" "wordpress_image" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "wordpress-*"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}