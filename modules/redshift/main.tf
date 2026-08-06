resource "aws_security_group" "redshift" {
  name_prefix = "${var.namespace_name}-"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 5439
    to_port         = 5439
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_redshiftserverless_namespace" "this" {
  namespace_name      = var.namespace_name
  kms_key_id           = var.kms_key_arn
  db_name              = var.database_name
  iam_roles            = [var.spectrum_role_arn]
  tags                 = var.tags
}

resource "aws_redshiftserverless_workgroup" "this" {
  namespace_name     = aws_redshiftserverless_namespace.this.namespace_name
  workgroup_name     = var.workgroup_name
  base_capacity      = var.base_capacity_rpu
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.redshift.id]
  publicly_accessible = false
  tags               = var.tags
}
