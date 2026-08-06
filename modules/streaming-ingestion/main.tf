# Kinesis chosen over MSK for the reference build - materially cheaper for
# a dev/learning environment while teaching the same provisioning patterns
# (encryption, IAM-scoped producer/consumer access, retention). Swap for an
# aws_msk_cluster resource here if the real workload needs Kafka semantics.

resource "aws_kinesis_stream" "this" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = var.retention_hours

  encryption_type = "KMS"
  kms_key_id      = var.kms_key_arn

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = var.tags
}

data "aws_iam_policy_document" "producer" {
  statement {
    actions   = ["kinesis:PutRecord", "kinesis:PutRecords", "kinesis:DescribeStreamSummary"]
    resources = [aws_kinesis_stream.this.arn]
  }
}

data "aws_iam_policy_document" "consumer" {
  statement {
    actions = [
      "kinesis:GetRecords", "kinesis:GetShardIterator",
      "kinesis:DescribeStream", "kinesis:ListShards"
    ]
    resources = [aws_kinesis_stream.this.arn]
  }
}

resource "aws_iam_policy" "producer" {
  name   = "${var.stream_name}-producer-policy"
  policy = data.aws_iam_policy_document.producer.json
}

resource "aws_iam_policy" "consumer" {
  name   = "${var.stream_name}-consumer-policy"
  policy = data.aws_iam_policy_document.consumer.json
}
