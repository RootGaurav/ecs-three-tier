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

  # <<-EOF strips leading TABS only — all heredoc content is flush-left.
  # The inner telegraf heredoc uses quoted <<'EOT' so bash variables like
  # $INSTANCE_ID are NOT expanded by Terraform's template engine at plan time.
  # ${var.cluster_name} and ${var.influxdb_host} are injected by Terraform
  # before the script runs, which is correct and intentional.
  user_data = base64encode(templatefile("${path.module}/userdata.sh.tftpl", {
    cluster_name  = var.cluster_name
    influxdb_host = var.influxdb_host
  }))
}

resource "aws_autoscaling_group" "frontend" {
  name = "ecs-frontend-asg"

  min_size              = 1
  desired_capacity      = 1
  max_size              = 2
  protect_from_scale_in = true

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

  min_size              = 1
  desired_capacity      = 1
  max_size              = 2
  protect_from_scale_in = true

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

    managed_draining               = "ENABLED"
    managed_termination_protection = "ENABLED"
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

    managed_draining               = "ENABLED"
    managed_termination_protection = "ENABLED"
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
