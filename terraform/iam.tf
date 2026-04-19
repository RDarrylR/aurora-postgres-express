# ---------------------------------------------------------------------------
# App role: least-privilege for application code (app_user only, not postgres)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "app_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    # Narrow this to the specific principal that runs your app.
    # Example: an EC2 instance profile, a Lambda execution role, an ECS task role.
    # Using account root here so the demo works from any IAM identity in the account.
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "app_db_connect" {
  statement {
    effect  = "Allow"
    actions = ["rds-db:connect"]
    resources = [
      "arn:aws:rds-db:${local.region}:${local.account_id}:dbuser:${data.aws_rds_cluster.express.cluster_resource_id}/${var.db_user}",
    ]
  }
}

resource "aws_iam_role" "app" {
  name                 = "${local.cluster_id}-app"
  assume_role_policy   = data.aws_iam_policy_document.app_assume_role.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "app_db_connect" {
  name   = "db-connect"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_db_connect.json
}

# ---------------------------------------------------------------------------
# Bootstrap role: one-time schema setup as admin (postgres user)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "bootstrap_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "bootstrap_db_connect" {
  statement {
    effect  = "Allow"
    actions = ["rds-db:connect"]
    resources = [
      "arn:aws:rds-db:${local.region}:${local.account_id}:dbuser:${data.aws_rds_cluster.express.cluster_resource_id}/postgres",
    ]
  }
}

resource "aws_iam_role" "bootstrap" {
  name                 = "${local.cluster_id}-bootstrap"
  assume_role_policy   = data.aws_iam_policy_document.bootstrap_assume_role.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "bootstrap_db_connect" {
  name   = "db-connect"
  role   = aws_iam_role.bootstrap.id
  policy = data.aws_iam_policy_document.bootstrap_db_connect.json
}
