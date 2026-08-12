#########################################
# EXISTING ECS TASK EXECUTION ROLE
#########################################

data "aws_iam_role" "ecs_execution" {
  name = "ecs-task-execution-role"
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = data.aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#########################################
# ECS SECRETS MANAGER ACCESS
#########################################

resource "aws_iam_policy" "ecs_secrets" {

  name = "ecs-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secret_attach" {

  role = data.aws_iam_role.ecs_execution.name

  policy_arn = aws_iam_policy.ecs_secrets.arn
}

#########################################
# EC2 ROLE (JENKINS / TIG / ELK)
#########################################

resource "aws_iam_role" "ec2_role" {

  name = "three-tier-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

#########################################
# INSTANCE PROFILE
#########################################

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "three-tier-ec2-profile"

  role = aws_iam_role.ec2_role.name
}

#########################################
# AWS MANAGED POLICIES
#########################################

resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {

  role = aws_iam_role.ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#########################################
# JENKINS POLICY
#########################################

resource "aws_iam_policy" "jenkins_policy" {

  name = "three-tier-jenkins-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      #################################
      # ECR
      #################################

      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]

        Resource = "*"
      },

      #################################
      # ECS
      #################################

      {
        Effect = "Allow"

        Action = [
          "ecs:*"
        ]

        Resource = "*"
      },

      #################################
      # EC2
      #################################

      {
        Effect = "Allow"

        Action = [
          "ec2:*"
        ]

        Resource = "*"
      },

      #################################
      # ASG
      #################################

      {
        Effect = "Allow"

        Action = [
          "autoscaling:*"
        ]

        Resource = "*"
      },

      #################################
      # ALB
      #################################

      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:*"
        ]

        Resource = "*"
      },

      #################################
      # CLOUDWATCH
      #################################

      {
        Effect = "Allow"

        Action = [
          "cloudwatch:*",
          "logs:*"
        ]

        Resource = "*"
      },

      #################################
      # SSM
      #################################

      {
        Effect = "Allow"

        Action = [
          "ssm:*"
        ]

        Resource = "*"
      },

      #################################
      # SECRETS
      #################################

      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "*"
      },

      #################################
      # S3 (Terraform Backend)
      #################################

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = "*"
      },

      #################################
      # IAM PASS ROLE
      #################################

      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_policy_attach" {

  role = aws_iam_role.ec2_role.name

  policy_arn = aws_iam_policy.jenkins_policy.arn
}