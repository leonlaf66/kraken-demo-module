# Storage Module

## Overview

This module provisions the complete data lake storage layer for the Kraken Demo platform, implementing a medallion architecture with MNPI (Material Non-Public Information) and Public data segregation.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Data Lake Storage                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │  Raw Layer  │    │  Curated    │    │  Analytics  │             │
│  │             │ -> │   Layer     │ -> │   Layer     │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
│        │                  │                  │                       │
│   ┌────┴────┐        ┌────┴────┐        ┌────┴────┐                │
│   │  MNPI   │        │  MNPI   │        │  MNPI   │                │
│   │ Bucket  │        │ Bucket  │        │ Bucket  │                │
│   └─────────┘        └─────────┘        └─────────┘                │
│   ┌─────────┐        ┌─────────┐        ┌─────────┐                │
│   │ Public  │        │ Public  │        │ Public  │                │
│   │ Bucket  │        │ Bucket  │        │ Bucket  │                │
│   └─────────┘        └─────────┘        └─────────┘                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Glue Catalog Databases                    │   │
│  │  raw_mnpi, raw_public, curated_mnpi, curated_public,        │   │
│  │  analytics_mnpi, analytics_public                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────┐    ┌─────────────────┐                        │
│  │    KMS Key      │    │    KMS Key      │                        │
│  │   (MNPI)        │    │   (Public)      │                        │
│  └─────────────────┘    └─────────────────┘                        │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │           CloudTrail (Audit Logging)                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

- **6 S3 Buckets**: Organized by layer (raw, curated, analytics) and sensitivity (MNPI, public)
- **2 KMS Keys**: Separate encryption keys for MNPI and public data
- **6 Glue Databases**: Pre-configured catalog databases for each bucket
- **CloudTrail**: Data access audit logging for compliance
- **Versioning**: Enabled on all buckets for data protection
- **Lifecycle Rules**: Automatic transition to cheaper storage classes

## Usage

```hcl
module "storage" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//storage?ref=v1.0.0"

  app_name          = "kraken-demo"
  env               = "dev"
  region            = "us-east-1"
  account_id        = "123456789012"
  common_tags       = var.common_tags
  audit_bucket_name = "kraken-demo-dev-audit"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `app_name` | Application name for resource naming | `string` | n/a | yes |
| `env` | Environment (dev, qa, prod) | `string` | n/a | yes |
| `region` | AWS region | `string` | n/a | yes |
| `account_id` | AWS account ID | `string` | n/a | yes |
| `common_tags` | Tags to apply to all resources | `map(string)` | n/a | yes |
| `audit_bucket_name` | S3 bucket for CloudTrail logs | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `kms_key_mnpi_arn` | ARN of KMS key for MNPI data |
| `kms_key_public_arn` | ARN of KMS key for public data |
| `bucket_raw_mnpi_arn` | ARN of raw MNPI bucket |
| `bucket_raw_mnpi_id` | Name of raw MNPI bucket |
| `bucket_raw_public_arn` | ARN of raw public bucket |
| `bucket_raw_public_id` | Name of raw public bucket |
| `bucket_curated_mnpi_arn` | ARN of curated MNPI bucket |
| `bucket_curated_public_arn` | ARN of curated public bucket |
| `bucket_analytics_mnpi_arn` | ARN of analytics MNPI bucket |
| `bucket_analytics_public_arn` | ARN of analytics public bucket |
| `glue_database_raw_mnpi_name` | Glue database for raw MNPI |
| `glue_database_raw_public_name` | Glue database for raw public |
| `glue_database_curated_mnpi_name` | Glue database for curated MNPI |
| `glue_database_curated_public_name` | Glue database for curated public |
| `glue_database_analytics_mnpi_name` | Glue database for analytics MNPI |
| `glue_database_analytics_public_name` | Glue database for analytics public |
| `cloudtrail_name` | CloudTrail trail name |
| `audit_bucket_name` | Audit bucket name |

## S3 Bucket Naming Convention

```
{app_name}-{env}-{layer}-{sensitivity}
Example: kraken-demo-dev-raw-mnpi
```

## Security Considerations

1. **MNPI Data Isolation**: MNPI buckets use a separate KMS key with stricter key policies
2. **Server-Side Encryption**: All buckets enforce SSE-KMS encryption
3. **Public Access Blocked**: All buckets have public access blocks enabled
4. **Audit Logging**: CloudTrail logs all data events for compliance
5. **Versioning**: Protects against accidental deletion

## Lifecycle Policies

| Layer | MNPI Retention | Public Retention | Glacier Transition |
|-------|---------------|------------------|-------------------|
| Raw | 90 days | 90 days | After 30 days |
| Curated | 1 year | 1 year | After 90 days |
| Analytics | 2 years | 2 years | After 180 days |

## Dependencies

- AWS Provider >= 5.0
- Existing VPC (for VPC endpoints if configured)

## Related Modules

- [msk](../msk) - MSK cluster that writes to these buckets
- [msk-connect](../msk-connect) - Connectors that sink data to S3
- [athena](../athena) - Query layer for this storage
