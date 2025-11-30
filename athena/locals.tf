locals {
  # Layer -> Sensitivity -> Bucket ARN mapping
  bucket_map = {
    raw = {
      mnpi   = var.buckets.raw_mnpi
      public = var.buckets.raw_public
    }
    curated = {
      mnpi   = var.buckets.curated_mnpi
      public = var.buckets.curated_public
    }
    analytics = {
      mnpi   = var.buckets.analytics_mnpi
      public = var.buckets.analytics_public
    }
  }

  # Layer -> Sensitivity -> Glue Database mapping
  database_map = {
    raw = {
      mnpi   = var.glue_databases.raw_mnpi
      public = var.glue_databases.raw_public
    }
    curated = {
      mnpi   = var.glue_databases.curated_mnpi
      public = var.glue_databases.curated_public
    }
    analytics = {
      mnpi   = var.glue_databases.analytics_mnpi
      public = var.glue_databases.analytics_public
    }
  }

  # For each user group, compute which buckets they can access
  user_group_buckets = {
    for group_name, config in var.user_groups : group_name => flatten([
      for layer in config.layers : [
        local.bucket_map[layer]["public"],
        config.mnpi_access ? local.bucket_map[layer]["mnpi"] : null
      ]
    ])
  }

  # For each user group, compute which Glue databases they can access
  user_group_databases = {
    for group_name, config in var.user_groups : group_name => flatten([
      for layer in config.layers : [
        local.database_map[layer]["public"],
        config.mnpi_access ? local.database_map[layer]["mnpi"] : null
      ]
    ])
  }

  # For each user group, compute which KMS keys they need
  user_group_kms_keys = {
    for group_name, config in var.user_groups : group_name => compact([
      var.kms_keys.public,
      config.mnpi_access ? var.kms_keys.mnpi : null
    ])
  }
}
