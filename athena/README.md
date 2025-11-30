# Athena Module

Athena query layer with role-based access control for MNPI/Public data separation.

## Resources Created

- Athena workgroups (per user group)
- IAM roles with least-privilege policies
- Query results S3 bucket

## User Groups

| Group | MNPI Access | Layers | MFA Required |
|-------|-------------|--------|--------------|
| finance_analysts | Yes | analytics | Yes |
| data_analysts | No | analytics | No |
| data_engineers | Yes | raw, curated, analytics | Yes |

## Usage

```hcl
module "athena" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//athena?ref=main"

  app_name   = "kraken-demo"
  env        = "dev"
  region     = "us-east-1"
  account_id = "123456789012"

  buckets = {
    raw_mnpi         = module.storage.bucket_raw_mnpi_arn
    raw_public       = module.storage.bucket_raw_public_arn
    curated_mnpi     = module.storage.bucket_curated_mnpi_arn
    curated_public   = module.storage.bucket_curated_public_arn
    analytics_mnpi   = module.storage.bucket_analytics_mnpi_arn
    analytics_public = module.storage.bucket_analytics_public_arn
  }

  kms_keys = {
    mnpi   = module.storage.kms_key_mnpi_arn
    public = module.storage.kms_key_public_arn
  }

  glue_databases = {
    raw_mnpi         = module.storage.glue_database_raw_mnpi_name
    # ...
  }
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| buckets | object | yes | S3 bucket ARNs by layer/sensitivity |
| kms_keys | object | yes | KMS key ARNs |
| glue_databases | object | yes | Glue database names |
| user_groups | map(object) | no | User group configurations |

## Outputs

| Name | Description |
|------|-------------|
| workgroups | Workgroup names and ARNs |
| roles | IAM role names and ARNs |
| access_matrix | Access summary by user group |
| query_results_bucket | Query results bucket info |

## Assuming Roles

```bash
# Finance Analyst (requires MFA)
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/kraken-demo-finance-analysts-dev \
  --role-session-name finance-query \
  --serial-number arn:aws:iam::123456789012:mfa/user \
  --token-code 123456
```
