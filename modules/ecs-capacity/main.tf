data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_template" "ecs" {
  name_prefix = "ecs-node-"

  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "c7i-flex.large"

  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  vpc_security_group_ids = [var.ecs_node_sg]

  # NOTE: <<-EOF strips leading TABS only, not spaces.
  # All heredoc content below is flush-left (no indentation) to prevent
  # spaces leaking into /etc/ecs/ecs.config and breaking ECS agent registration.
  user_data = base64encode(<<-EOF
#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Write ECS config BEFORE the agent starts.
# ecs-init (pre-installed on ECS-optimized AMI) reads /etc/ecs/ecs.config at
# boot via systemd — before user_data runs. We stop it, write config, restart.
# IMPORTANT: no leading spaces in the heredoc or the agent ignores the values.
# ---------------------------------------------------------------------------
systemctl stop ecs 2>/dev/null || true

mkdir -p /etc/ecs
# Use a temp file + mv for atomic write
cat > /tmp/ecs.config.tmp <<ECSCONFIG
ECS_CLUSTER=${var.cluster_name}
ECS_ENABLE_CONTAINER_METADATA=true
ECS_LOGLEVEL=info
ECSCONFIG
mv /tmp/ecs.config.tmp /etc/ecs/ecs.config

systemctl enable ecs
systemctl start ecs

until docker info >/dev/null 2>&1; do
  echo "Waiting for Docker..."
  sleep 2
done

# Wait for ECS agent to register with the cluster
for i in $(seq 1 30); do
  if curl -sf http://localhost:51678/v1/metadata | grep -q "Cluster"; then
    echo "ECS agent registered successfully."
    break
  fi
  echo "Waiting for ECS agent... attempt $i"
  sleep 5
done

# ---------------------------------------------------------------------------
# Telegraf for node-level metrics
# ---------------------------------------------------------------------------
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
AZ=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Again: no leading spaces — telegraf config is strict TOML
cat > /tmp/telegraf.conf <<EOT
[global_tags]
  cluster           = "${var.cluster_name}"
  instance_id       = "$INSTANCE_ID"
  private_ip        = "$PRIVATE_IP"
  availability_zone = "$AZ"

[[inputs.tail]]
  files          = ["/host/var/log/messages", "/host/var/log/ecs/ecs-agent.log"]
  from_beginning = false
  pipe           = false
  data_format    = "grok"
  grok_patterns  = ["%%{GREEDYDATA:message}"]
  name_override  = "ecs_node_log"

[[inputs.cpu]]
  percpu           = false
  totalcpu         = true
  collect_cpu_time = false

[[inputs.mem]]

[[inputs.disk]]
  ignore_fs    = ["tmpfs", "devtmpfs", "overlay", "squashfs"]
  mount_points = ["/"]

[[outputs.influxdb]]
  urls                   = ["http://${var.influxdb_host}:8086"]
  database               = "telegraf"
  skip_database_creation = false
EOT

docker rm -f telegraf >/dev/null 2>&1 || true

docker run -d \
  --name telegraf \
  --restart unless-stopped \
  -e HOST_ETC=/host/etc \
  -e HOST_PROC=/host/proc \
  -e HOST_SYS=/host/sys \
  -e HOST_VAR=/host/var \
  -e HOST_MOUNT_PREFIX=/hostfs \
  -v /tmp/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
  -v /etc:/host/etc:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /var/log:/host/var/log:ro \
  -v /:/hostfs:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  telegraf:1.31
EOF
  )
}

resource "aws_autoscaling_group" "frontend" {
  name = "ecs-frontend-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.ecs.id
    version = aws_launch_template.ecs.latest_version
  }

  tag {
    key                 = "Name"
    value               = "ecs-frontend-node"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  force_delete = true
}

resource "aws_autoscaling_group" "backend" {
  name = "ecs-backend-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.ecs.id
    version = aws_launch_template.ecs.latest_version
  }

  tag {
    key                 = "Name"
    value               = "ecs-backend-node"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  force_delete = true
}

resource "aws_ecs_capacity_provider" "frontend" {
  name = "three-tier-frontend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.frontend.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }

    managed_draining = "ENABLED"
  }
}

resource "aws_ecs_capacity_provider" "backend" {
  name = "three-tier-backend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.backend.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }

    managed_draining = "ENABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = var.cluster_name

  capacity_providers = [aws_ecs_capacity_provider.frontend.name, aws_ecs_capacity_provider.backend.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.frontend.name
    weight            = 1
  }

  depends_on = [
    aws_ecs_capacity_provider.frontend,
    aws_ecs_capacity_provider.backend,
  ]
}
