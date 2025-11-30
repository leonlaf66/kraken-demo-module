# Storage Module

S3-based Data Lake with MNPI/Public isolation, KMS encryption, Glue Catalog, and CloudTrail auditing.

## Resources Created

- 6 S3 buckets (raw/curated/analytics × mnpi/public)
- 2 KMS keys (MNPI and Public)
- 6 Glue databases
- CloudTrail for data access auditing
- S3 access logging bucket

## Usage

```hcl
module "storage" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//storage?ref=main"

  app_name   = "kraken-demo"
  env        = "dev"
  region     = "us-east-1"
  account_id = "123456789012"
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| app_name | string | yes | - | Application name |
| env | string | yes | - | Environment (dev/qa/staging/prod) |
| region | string | yes | - | AWS region |
| account_id | string | yes | - | AWS account ID |
| common_tags | map(string) | no | {} | Common tags |
| enable_mnpi_object_lock | bool | no | false | Enable WORM for MNPI buckets |
| enable_access_logging | bool | no | true | Enable S3 access logging |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_mnpi_arn | KMS key ARN for MNPI data |
| kms_key_public_arn | KMS key ARN for Public data |
| bucket_*_arn/id | ARN and ID for each bucket |
| glue_database_*_name | Glue database names |
| cloudtrail_arn | CloudTrail trail ARN |

## Bucket Naming

`{app_name}-{layer}-{sensitivity}-{account_id}-{env}`

Example: `kraken-demo-raw-mnpi-123456789012-dev`
