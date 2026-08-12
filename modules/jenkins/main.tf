data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "al2023-ami-*-x86_64"
    ]
  }
}
resource "aws_eip" "jenkins" {

  instance = aws_instance.jenkins.id

  domain = "vpc"
}
resource "aws_instance" "jenkins" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = "c7i-flex.large"

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [
    var.jenkins_sg
  ]

  key_name = var.key_name

  iam_instance_profile = var.instance_profile

  user_data = file("${path.module}/userdata.sh")

  tags = {
    Name = "jenkins-server"
  }
}