resource "aws_iam_role" "this" {
  for_each = var.user_groups

  name        = "${var.app_name}-${replace(each.key, "_", "-")}-${var.env}"
  description = each.value.description

  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(var.common_tags, {
    Name       = "${var.app_name}-${replace(each.key, "_", "-")}"
    UserGroup  = each.key
    MNPIAccess = tostring(each.value.mnpi_access)
  })
}

resource "aws_iam_role_policy_attachment" "athena_workgroup" {
  for_each = var.user_groups

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.athena_workgroup[each.key].arn
}

resource "aws_iam_role_policy_attachment" "glue_catalog" {
  for_each = var.user_groups

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.glue_catalog[each.key].arn
}

resource "aws_iam_role_policy_attachment" "s3_data_lake" {
  for_each = var.user_groups

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.s3_data_lake[each.key].arn
}

resource "aws_iam_role_policy_attachment" "s3_query_results" {
  for_each = var.user_groups

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.s3_query_results[each.key].arn
}

resource "aws_iam_role_policy_attachment" "kms" {
  for_each = var.user_groups

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.kms[each.key].arn
}
