# Athena Module

## Overview

This module provisions Amazon Athena workgroups with role-based access control for querying data lake content. It implements user group isolation with separate workgroups, IAM roles, and permission boundaries for MNPI vs Public data access.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                             Athena Module                                     │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                      Query Results Bucket                                │ │
│  │                    (S3 with KMS encryption)                              │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         User Groups                                      │ │
│  │  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐   │ │
│  │  │  Finance Analysts │  │   Data Analysts   │  │  Data Engineers   │   │ │
│  │  │                   │  │                   │  │                   │   │ │
│  │  │ ┌───────────────┐ │  │ ┌───────────────┐ │  │ ┌───────────────┐ │   │ │
│  │  │ │   Workgroup   │ │  │ │   Workgroup   │ │  │ │   Workgroup   │ │   │ │
│  │  │ │ (10GB limit)  │ │  │ │ (10GB limit)  │ │  │ │ (20GB limit)  │ │   │ │
│  │  │ └───────────────┘ │  │ └───────────────┘ │  │ └───────────────┘ │   │ │
│  │  │ ┌───────────────┐ │  │ ┌───────────────┐ │  │ ┌───────────────┐ │   │ │
│  │  │ │   IAM Role    │ │  │ │   IAM Role    │ │  │ │   IAM Role    │ │   │ │
│  │  │ └───────────────┘ │  │ └───────────────┘ │  │ └───────────────┘ │   │ │
│  │  │                   │  │                   │  │                   │   │ │
│  │  │ Access:           │  │ Access:           │  │ Access:           │   │ │
│  │  │ - Analytics MNPI  │  │ - Analytics Public│  │ - All Layers      │   │ │
│  │  │ - Analytics Public│  │                   │  │ - MNPI + Public   │   │ │
│  │  │ - MFA Required    │  │                   │  │ - MFA Required    │   │ │
│  │  └───────────────────┘  └───────────────────┘  └───────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    Data Access Permissions                               │ │
│  │                                                                          │ │
│  │  Layer         │  Finance Analysts  │  Data Analysts  │  Data Engineers │ │
│  │  ─────────────────────────────────────────────────────────────────────  │ │
│  │  Raw MNPI      │        ❌          │       ❌        │       ✅        │ │
│  │  Raw Public    │        ❌          │       ❌        │       ✅        │ │
│  │  Curated MNPI  │        ❌          │       ❌        │       ✅        │ │
│  │  Curated Public│        ❌          │       ❌        │       ✅        │ │
│  │  Analytics MNPI│        ✅          │       ❌        │       ✅        │ │
│  │  Analytics Pub │        ✅          │       ✅        │       ✅        │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Role-Based Access**: Separate workgroups per user group
- **MNPI Isolation**: Strict separation of sensitive data access
- **Query Limits**: Configurable bytes scanned limits per group
- **MFA Enforcement**: Optional MFA requirement for sensitive data
- **Automatic IAM**: IAM roles with least-privilege policies
- **Query Results**: Encrypted S3 bucket with lifecycle rules

## Usage

```hcl
module "athena" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//athena?ref=v1.0.0"

  app_name    = "kraken-demo"
  env         = "dev"
  region      = "us-east-1"
  account_id  = "123456789012"
  common_tags = var.common_tags

  # S3 Buckets (from storage module)
  buckets = {
    raw_mnpi         = module.storage.bucket_raw_mnpi_arn
    raw_public       = module.storage.bucket_raw_public_arn
    curated_mnpi     = module.storage.bucket_curated_mnpi_arn
    curated_public   = module.storage.bucket_curated_public_arn
    analytics_mnpi   = module.storage.bucket_analytics_mnpi_arn
    analytics_public = module.storage.bucket_analytics_public_arn
  }

  # KMS Keys (from storage module)
  kms_keys = {
    mnpi   = module.storage.kms_key_mnpi_arn
    public = module.storage.kms_key_public_arn
  }

  # Glue Databases (from storage module)
  glue_databases = {
    raw_mnpi         = module.storage.glue_database_raw_mnpi_name
    raw_public       = module.storage.glue_database_raw_public_name
    curated_mnpi     = module.storage.glue_database_curated_mnpi_name
    curated_public   = module.storage.glue_database_curated_public_name
    analytics_mnpi   = module.storage.glue_database_analytics_mnpi_name
    analytics_public = module.storage.glue_database_analytics_public_name
  }

  # Optional: Custom user groups
  user_groups = {
    finance_analysts = {
      description  = "Finance Analysts - Analytics layer (MNPI + Public)"
      mnpi_access  = true
      layers       = ["analytics"]
      mfa_required = true
    }
    data_analysts = {
      description  = "Data Analysts - Analytics layer (Public only)"
      mnpi_access  = false
      layers       = ["analytics"]
      mfa_required = false
    }
    data_engineers = {
      description            = "Data Engineers - Full access to all layers"
      mnpi_access            = true
      layers                 = ["raw", "curated", "analytics"]
      mfa_required           = true
      bytes_limit_multiplier = 2
      can_manage_tables      = true
    }
  }

  # Optional: Query limits
  athena_bytes_scanned_cutoff = 10737418240  # 10 GB
  query_result_retention_days = 30
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `app_name` | Application name | `string` | n/a | yes |
| `env` | Environment | `string` | n/a | yes |
| `region` | AWS region | `string` | n/a | yes |
| `account_id` | AWS account ID | `string` | n/a | yes |
| `common_tags` | Common tags | `map(string)` | `{}` | no |
| `buckets` | Data lake bucket ARNs | See below | n/a | yes |
| `kms_keys` | KMS key ARNs | See below | n/a | yes |
| `glue_databases` | Glue database names | See below | n/a | yes |
| `user_groups` | User group configurations | See below | See defaults | no |
| `athena_bytes_scanned_cutoff` | Base bytes limit | `number` | `10737418240` | no |
| `query_result_retention_days` | Result retention | `number` | `30` | no |

### Buckets Input

```hcl
buckets = {
  raw_mnpi         = string  # ARN
  raw_public       = string  # ARN
  curated_mnpi     = string  # ARN
  curated_public   = string  # ARN
  analytics_mnpi   = string  # ARN
  analytics_public = string  # ARN
}
```

### KMS Keys Input

```hcl
kms_keys = {
  mnpi   = string  # ARN
  public = string  # ARN
}
```

### User Groups Configuration

```hcl
user_groups = {
  group_name = {
    description            = string        # Group description
    mnpi_access            = bool          # Can access MNPI data
    layers                 = list(string)  # ["raw", "curated", "analytics"]
    mfa_required           = bool          # Require MFA for queries
    bytes_limit_multiplier = number        # Multiplier for query limit (default: 1)
    can_manage_tables      = bool          # Can create/alter tables (default: false)
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `workgroups` | Map of workgroup names and ARNs |
| `roles` | Map of IAM role names and ARNs |
| `query_results_bucket` | Query results bucket details |
| `access_matrix` | Summary of access permissions |

## Default User Groups

| Group | MNPI Access | Layers | MFA | Query Limit | Table Mgmt |
|-------|-------------|--------|-----|-------------|------------|
| finance_analysts | ✅ | analytics | ✅ | 10 GB | ❌ |
| data_analysts | ❌ | analytics | ❌ | 10 GB | ❌ |
| data_engineers | ✅ | all | ✅ | 20 GB | ✅ |

## IAM Role Permissions

### All Roles Include
- Athena query execution in assigned workgroup
- S3 read access to query results bucket
- Glue catalog read access for assigned databases

### MNPI Roles Add
- KMS decrypt for MNPI key
- S3 read for MNPI buckets
- Glue access for MNPI databases

### Data Engineer Roles Add
- Table management (CreateTable, DeleteTable, UpdateTable)
- Partition management
- Higher query limits

## Query Results Bucket

- **Encryption**: SSE-S3
- **Versioning**: Enabled
- **Lifecycle**: Objects expire after configured days
- **Access**: Only Athena workgroups can write

## Security Considerations

1. **MFA Enforcement**: Required for MNPI access via IAM conditions
2. **Query Limits**: Prevent runaway queries with bytes scanned limits
3. **Result Encryption**: All query results encrypted at rest
4. **Least Privilege**: Each role only accesses required databases/buckets
5. **Workgroup Isolation**: Users can only see their workgroup results

## Usage Examples

### Assume Role for Queries

```bash
# Get temporary credentials
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/kraken-demo-dev-athena-finance_analysts" \
  --role-session-name "athena-session"

# Run query
aws athena start-query-execution \
  --query-string "SELECT * FROM analytics_mnpi.trades LIMIT 10" \
  --work-group "kraken-demo-dev-finance_analysts"
```

### In Python (boto3)

```python
import boto3

# Assume role first
sts = boto3.client('sts')
credentials = sts.assume_role(
    RoleArn='arn:aws:iam::123456789012:role/kraken-demo-dev-athena-data_analysts',
    RoleSessionName='athena-session'
)['Credentials']

# Create Athena client with assumed credentials
athena = boto3.client(
    'athena',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken']
)

# Run query
response = athena.start_query_execution(
    QueryString='SELECT * FROM analytics_public.market_data LIMIT 10',
    WorkGroup='kraken-demo-dev-data_analysts'
)
```

## Dependencies

- AWS Provider >= 5.0
- Existing data lake buckets (from storage module)
- Glue catalog databases (from storage module)
- KMS keys (from storage module)

## Related Modules

- [storage](../storage) - Creates buckets, Glue databases, and KMS keys
- [msk-connect](../msk-connect) - Populates the data lake via S3 sink
