locals {
  name_prefix = "dataforge-${var.environment}"
  common_tags = {
    Project             = "dataforge"
    Environment         = var.environment
    Owner               = var.owner
    CostCenter          = var.cost_center
    DataClassification  = "internal"
  }

  # Construct DAG bucket ARN directly to prevent circular dependencies between MWAA & IAM
  dag_bucket_arn = "arn:aws:s3:::${local.name_prefix}-airflow-dags"
}

module "networking" {
  source      = "../../modules/networking"
  name_prefix = local.name_prefix
  aws_region  = var.aws_region
  tags        = local.common_tags
}

module "kms_datalake" {
  source          = "../../modules/kms"
  key_alias       = "${local.name_prefix}-datalake"
  key_description = "CMK for dataforge ${var.environment} data lake"
  tags            = local.common_tags
}

module "data_lake" {
  source        = "../../modules/data-lake-storage"
  bucket_prefix = local.name_prefix
  kms_key_arn   = module.kms_datalake.key_arn
  tags          = local.common_tags

  tier_writer_role_arns = {
    raw       = module.iam_roles.glue_role_arn
    curated   = module.iam_roles.emr_role_arn
    analytics = module.iam_roles.emr_role_arn
  }
}

module "iam_roles" {
  source               = "../../modules/iam-roles"
  name_prefix          = local.name_prefix
  raw_bucket_arn        = module.data_lake.bucket_arns["raw"]
  curated_bucket_arn    = module.data_lake.bucket_arns["curated"]
  analytics_bucket_arn  = module.data_lake.bucket_arns["analytics"]
  dag_bucket_arn        = local.dag_bucket_arn
  tags                  = local.common_tags
}

module "mwaa" {
  source              = "../../modules/mwaa"
  environment_name    = "${local.name_prefix}-airflow"
  execution_role_arn  = module.iam_roles.mwaa_role_arn
  vpc_id              = module.networking.vpc_id
  subnet_ids          = slice(module.networking.private_subnet_ids, 0, 2)
  environment_class   = "mw1.small"
  tags                = local.common_tags
}

module "glue_catalog" {
  source          = "../../modules/glue-catalog"
  name_prefix     = replace(local.name_prefix, "-", "_")
  glue_role_arn   = module.iam_roles.glue_role_arn
  raw_bucket_name = module.data_lake.bucket_names["raw"]
}

module "lake_formation" {
  source          = "../../modules/lake-formation"
  admin_role_arn  = var.admin_role_arn
  glue_role_arn   = module.iam_roles.glue_role_arn
  database_names  = module.glue_catalog.database_names
}

module "streaming" {
  source           = "../../modules/streaming-ingestion"
  stream_name      = "${local.name_prefix}-events"
  kms_key_arn      = module.kms_datalake.key_arn
  shard_count      = 2
  retention_hours  = 24
  tags             = local.common_tags
}

module "emr" {
  source                = "../../modules/emr-cluster"
  cluster_name          = "${local.name_prefix}-spark"
  vpc_id                = module.networking.vpc_id
  subnet_id             = module.networking.private_subnet_ids[0]
  emr_service_role_arn  = module.iam_roles.emr_role_arn
  emr_instance_profile  = module.iam_roles.emr_instance_profile_name
  log_uri               = "s3://${module.data_lake.bucket_names["raw"]}/emr-logs/"
  core_instance_count   = 2
  environment           = var.environment
  tags                  = local.common_tags
}

module "redshift" {
  source                     = "../../modules/redshift"
  namespace_name             = "${local.name_prefix}-warehouse"
  workgroup_name             = "${local.name_prefix}-wg"
  kms_key_arn                = module.kms_datalake.key_arn
  spectrum_role_arn          = module.iam_roles.emr_role_arn
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = module.networking.private_subnet_ids
  allowed_security_group_ids = []
  base_capacity_rpu          = 8
  tags                       = local.common_tags
}

module "secrets" {
  source       = "../../modules/secrets-manager"
  name_prefix  = local.name_prefix
  secret_names = ["source-db-conn", "saas-api-key"]
  kms_key_arn  = module.kms_datalake.key_arn
  tags         = local.common_tags
}

module "monitoring" {
  source               = "../../modules/monitoring"
  name_prefix          = local.name_prefix
  alert_email          = var.alert_email
  kinesis_stream_name  = module.streaming.stream_name
  tags                 = local.common_tags
}
