#!/usr/bin/env bash
# One-shot CLI approach to provision Aurora PostgreSQL Express without Terraform.
# Demonstrates that a usable cluster is one API call away.

set -euo pipefail

CLUSTER_ID="${CLUSTER_ID:-express-demo}"
REGION="${AWS_REGION:-us-east-1}"
DB_NAME="${DB_NAME:-appdb}"
MIN_ACU="${MIN_ACU:-0}"
MAX_ACU="${MAX_ACU:-4}"

echo "Creating Aurora PostgreSQL Express cluster: $CLUSTER_ID in $REGION"
echo "Note: Express config does not support --database-name at creation time."
echo "The app database will need to be created after the cluster is available."

aws rds create-db-cluster \
    --region "$REGION" \
    --db-cluster-identifier "$CLUSTER_ID" \
    --engine aurora-postgresql \
    --with-express-configuration \
    --serverless-v2-scaling-configuration "{\"MinCapacity\":$MIN_ACU,\"MaxCapacity\":$MAX_ACU}"

echo "Waiting for cluster..."
aws rds wait db-cluster-available \
    --region "$REGION" \
    --db-cluster-identifier "$CLUSTER_ID"

ENDPOINT=$(aws rds describe-db-clusters \
    --region "$REGION" \
    --db-cluster-identifier "$CLUSTER_ID" \
    --query 'DBClusters[0].Endpoint' \
    --output text)

echo
echo "Cluster is available."
echo "Endpoint: $ENDPOINT"
echo
echo "Next: create the app database and apply the schema:"
echo "  export DB_ENDPOINT=$ENDPOINT"
echo "  export DB_USER=postgres"
echo "  export AWS_REGION=$REGION"
echo "  psql \"host=\$DB_ENDPOINT user=postgres dbname=postgres sslmode=verify-full sslrootcert=system\" -c \"CREATE DATABASE $DB_NAME;\""
echo "  psql \"host=\$DB_ENDPOINT user=postgres dbname=$DB_NAME sslmode=verify-full sslrootcert=system\" -f python/schema.sql"
