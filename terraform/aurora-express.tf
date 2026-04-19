resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  express_cluster_identifier = "${local.cluster_id}-${random_id.suffix.hex}"
}

# ---------------------------------------------------------------------------
# IMPORTANT: null_resource limitations
#
# 1. No drift detection. If someone changes min_acu/max_acu outside Terraform,
#    or the default Aurora PostgreSQL major version rolls forward, Terraform
#    will report "no changes." Do not treat this module as drift-safe.
#
# 2. The provisioner only re-runs when `triggers` change. Updating tags or
#    deletion_protection requires tearing down and recreating the cluster
#    unless you also run the AWS CLI manually.
#
# 3. Replace this with a native aws_rds_cluster resource once the provider
#    ships the with_express_configuration argument.
#    Track: https://github.com/hashicorp/terraform-provider-aws/issues/47117
# ---------------------------------------------------------------------------

resource "null_resource" "aurora_express_cluster" {
  triggers = {
    cluster_identifier = local.express_cluster_identifier
    region             = var.aws_region
    min_acu            = var.min_acu
    max_acu            = var.max_acu
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      echo "Creating Aurora PostgreSQL Express cluster: ${local.express_cluster_identifier}"

      aws rds create-db-cluster \
        --region "${var.aws_region}" \
        --db-cluster-identifier "${local.express_cluster_identifier}" \
        --engine aurora-postgresql \
        --with-express-configuration \
        --serverless-v2-scaling-configuration '{"MinCapacity":${var.min_acu},"MaxCapacity":${var.max_acu}}' \
        ${var.deletion_protection ? "--deletion-protection" : "--no-deletion-protection"} \
        --tags "Key=Project,Value=${var.project_name}" "Key=Environment,Value=${var.environment}" \
        > /dev/null

      echo "Waiting for cluster to become available..."
      aws rds wait db-cluster-available \
        --region "${var.aws_region}" \
        --db-cluster-identifier "${local.express_cluster_identifier}"

      echo "Cluster is available."
    EOT
  }

  # Destroy provisioner uses a portable while-read loop instead of mapfile
  # (mapfile requires bash 4+; macOS ships bash 3.2 by default).
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      CLUSTER_ID="${self.triggers.cluster_identifier}"
      REGION="${self.triggers.region}"

      echo "Deleting writer instances for cluster $CLUSTER_ID"
      aws rds describe-db-instances \
        --region "$REGION" \
        --filters "Name=db-cluster-id,Values=$CLUSTER_ID" \
        --query 'DBInstances[].DBInstanceIdentifier' \
        --output text | tr '\t' '\n' | while read -r INSTANCE_ID; do
        [ -z "$INSTANCE_ID" ] && continue
        echo "  Deleting instance $INSTANCE_ID"
        aws rds delete-db-instance \
          --region "$REGION" \
          --db-instance-identifier "$INSTANCE_ID" \
          --skip-final-snapshot > /dev/null || true
      done

      echo "Deleting cluster $CLUSTER_ID"
      aws rds delete-db-cluster \
        --region "$REGION" \
        --db-cluster-identifier "$CLUSTER_ID" \
        --skip-final-snapshot > /dev/null || true

      aws rds wait db-cluster-deleted \
        --region "$REGION" \
        --db-cluster-identifier "$CLUSTER_ID" || true
    EOT
  }
}

data "aws_rds_cluster" "express" {
  cluster_identifier = local.express_cluster_identifier

  depends_on = [null_resource.aurora_express_cluster]
}
