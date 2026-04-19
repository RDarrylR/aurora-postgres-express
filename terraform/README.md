# Aurora PostgreSQL Express Configuration Terraform Module

Terraform that provisions an Aurora PostgreSQL Express cluster and the IAM role needed to connect with IAM authentication.

## What this module creates

- One Aurora PostgreSQL Express cluster (no VPC, internet access gateway enabled, IAM auth on by default)
- One IAM role that applications can assume to generate database auth tokens
- One inline policy granting `rds-db:connect` to the cluster for the configured user

## Why a null_resource wraps the AWS CLI

As of April 2026, the Terraform AWS provider does not yet expose the `--with-express-configuration` flag on `aws_rds_cluster`. The feature reached GA on March 25, 2026 and provider coverage is still catching up. Track [hashicorp/terraform-provider-aws#47117](https://github.com/hashicorp/terraform-provider-aws/issues/47117) for progress.

One open design question on that issue: the CreateCluster API with express configuration creates both a cluster and a serverless writer instance, which does not fit cleanly into Terraform's one-resource-per-state-entry model and causes orphan-instance errors on destroy. Until that is resolved, the module shells out to the AWS CLI inside a `null_resource` to create and tear down the cluster, then uses an `aws_rds_cluster` data source to read attributes back into Terraform state. The destroy provisioner explicitly deletes the child instance before the cluster. Everything downstream (IAM, outputs, app wiring) is plain HCL.

When native support lands, the `null_resource` can be replaced with a single `aws_rds_cluster` resource without changing the rest of the module.

## Usage

```bash
terraform init
terraform apply -var project_name=my-app -var environment=dev

eval "$(terraform output -json connection_hint | jq -r 'to_entries | .[] | "export \(.key)=\(.value)"')"
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Name prefix for resources | `aurora-express-demo` |
| `environment` | Environment tag | `dev` |
| `db_name` | Initial database name | `appdb` |
| `db_user` | App database role used for IAM auth | `app_user` |
| `min_acu` | Minimum ACUs (0 allows scale-to-zero) | `0` |
| `max_acu` | Maximum ACUs | `4` |
| `deletion_protection` | Enable deletion protection | `false` |

## Outputs

- `cluster_identifier`, `cluster_endpoint`, `reader_endpoint`
- `admin_user`, `database_name`
- `app_iam_role_arn`
- `connection_hint` (map of env vars to export)
