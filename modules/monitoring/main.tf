resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Example alarm - extend per-service (EMR step failures, MWAA task
# failures, Redshift disk usage) as those modules are wired in.
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  count               = var.kinesis_stream_name == "" ? 0 : 1
  alarm_name          = "${var.name_prefix}-kinesis-iterator-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 60000
  alarm_description   = "Consumers falling behind on the ingestion stream"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    StreamName = var.kinesis_stream_name
  }
}
