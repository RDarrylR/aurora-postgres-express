#!/usr/bin/env bash
# Tear down an Aurora PostgreSQL Express cluster created with create-express-cluster.sh.

set -euo pipefail

CLUSTER_ID="${CLUSTER_ID:-express-demo}"
REGION="${AWS_REGION:-us-east-1}"

echo "Deleting writer instances for $CLUSTER_ID"
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
        --skip-final-snapshot || true
done

echo "Deleting cluster $CLUSTER_ID"
aws rds delete-db-cluster \
    --region "$REGION" \
    --db-cluster-identifier "$CLUSTER_ID" \
    --skip-final-snapshot || true

aws rds wait db-cluster-deleted \
    --region "$REGION" \
    --db-cluster-identifier "$CLUSTER_ID"

echo "Done."
