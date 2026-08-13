
data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "influxdb" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"

  subnet_id                   = var.influxdb_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.influxdb_sg]

  iam_instance_profile = var.instance_profile

  user_data = templatefile("${path.module}/influxdb.sh.tftpl", {})

  tags = {
    Name = "influxdb"
  }
}

resource "aws_instance" "grafana" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  depends_on    = [aws_instance.influxdb]

  subnet_id                   = var.grafana_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.grafana_sg]

  iam_instance_profile = var.instance_profile

  user_data = templatefile("${path.module}/grafana.sh.tftpl", {
    influxdb_host           = aws_instance.influxdb.private_ip
    ecs_node_logs_dashboard = file("${path.module}/ecs-node-logs.dashboard.json")
  })

  tags = {
    Name = "grafana"
  }
}
