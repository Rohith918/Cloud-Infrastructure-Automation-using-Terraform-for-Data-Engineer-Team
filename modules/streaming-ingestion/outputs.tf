output "stream_arn" {
  value = aws_kinesis_stream.this.arn
}

output "stream_name" {
  value = aws_kinesis_stream.this.name
}

output "producer_policy_arn" {
  value = aws_iam_policy.producer.arn
}

output "consumer_policy_arn" {
  value = aws_iam_policy.consumer.arn
}
