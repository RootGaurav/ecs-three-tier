resource "aws_sns_topic" "alerts" {
  name = "prod-alerts"
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "ecs-high-cpu"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  period              = 300
  threshold           = 80
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
