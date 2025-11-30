resource "aws_glue_catalog_database" "datalake" {
  for_each = local.buckets

  name        = replace("${var.app_name}_${each.key}_${var.env}", "-", "_")
  description = "${title(each.value.tier)} layer ${upper(each.value.sensitivity)} data - ${var.env}"

  location_uri = "s3://${aws_s3_bucket.datalake[each.key].id}/"

  tags = merge(var.common_tags, {
    Tier        = title(each.value.tier)
    Sensitivity = upper(each.value.sensitivity)
  })
}
