resource "aws_security_group" "emr" {
  name_prefix = "${var.cluster_name}-"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_emr_cluster" "this" {
  name          = var.cluster_name
  release_label = var.release_label
  applications  = ["Spark"]

  service_role     = var.emr_service_role_arn
  log_uri          = var.log_uri
  autoscaling_role = var.emr_service_role_arn

  ec2_attributes {
    subnet_id                        = var.subnet_id
    instance_profile                 = var.emr_instance_profile
    emr_managed_master_security_group = aws_security_group.emr.id
    emr_managed_slave_security_group  = aws_security_group.emr.id
  }

  master_instance_group {
    instance_type = var.master_instance_type
  }

  core_instance_group {
    instance_type  = var.core_instance_type
    instance_count = var.core_instance_count

    bid_price = var.use_spot ? var.spot_bid_price : null
  }

  # Idle clusters cost money - not appropriate for a job-triggered pattern
  # driven by MWAA, which typically creates transient clusters per job. This
  # resource models a persistent cluster; see docs/RFC for the transient
  # (EMR-on-EKS / step-triggered) alternative.
  termination_protection = var.environment == "prod"

  tags = var.tags
}
