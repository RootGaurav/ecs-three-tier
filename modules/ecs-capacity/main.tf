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

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
              echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
              EOF
  )
}

resource "aws_autoscaling_group" "frontend" {
  name = "ecs-frontend-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 3

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

  force_delete = true
}

resource "aws_autoscaling_group" "backend" {
  name = "ecs-backend-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 3

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

  force_delete = true
}

resource "aws_ecs_capacity_provider" "frontend" {
  name = "three-tier-frontend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.frontend.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
    }

    managed_draining = "ENABLED"
  }
}

resource "aws_ecs_capacity_provider" "backend" {
  name = "three-tier-backend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.backend.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
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
