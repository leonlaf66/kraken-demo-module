locals {
  buckets = {
    # MNPI Zone
    raw_mnpi       = { tier = "raw", sensitivity = "mnpi" }
    curated_mnpi   = { tier = "curated", sensitivity = "mnpi" }
    analytics_mnpi = { tier = "analytics", sensitivity = "mnpi" }

    # Public Zone
    raw_public       = { tier = "raw", sensitivity = "public" }
    curated_public   = { tier = "curated", sensitivity = "public" }
    analytics_public = { tier = "analytics", sensitivity = "public" }
  }

  # Filter by sensitivity
  mnpi_buckets   = { for k, v in local.buckets : k => v if v.sensitivity == "mnpi" }
  public_buckets = { for k, v in local.buckets : k => v if v.sensitivity == "public" }
}
