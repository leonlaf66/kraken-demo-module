resource "aws_glue_catalog_database" "raw_mnpi" {
  name        = "kraken_raw_mnpi_${var.env}"
  description = "Raw MNPI Data (CDC/Kafka) - Restricted Access"
  
  location_uri = "s3://${aws_s3_bucket.raw_mnpi.bucket}/"
}

resource "aws_glue_catalog_database" "raw_public" {
  name        = "kraken_raw_public_${var.env}"
  description = "Raw Public Data (CDC/Kafka) - General Access"
  
  location_uri = "s3://${aws_s3_bucket.raw_public.bucket}/"
}