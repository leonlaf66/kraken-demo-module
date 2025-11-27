resource "aws_cloudtrail" "datalake_audit" {
  name                          = "${var.app_name}-datalake-audit-trail-${var.env}"
  s3_bucket_name                = var.audit_bucket_name
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.raw_mnpi.arn}/",
        "${aws_s3_bucket.raw_public.arn}/"
      ]
    }
  }
  
  tags = var.common_tags
}