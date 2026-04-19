.PHONY: help init fmt validate plan apply destroy install schema run-app cli-create cli-delete trad-init trad-plan trad-apply trad-destroy clean

PROJECT ?= express-notes
ENV     ?= dev
REGION  ?= us-east-1

help:
	@echo "Aurora PostgreSQL Express blog - make targets"
	@echo ""
	@echo "  init         Initialize Terraform in terraform/"
	@echo "  fmt          Terraform fmt"
	@echo "  validate     Terraform validate"
	@echo "  plan         Terraform plan (Aurora Express)"
	@echo "  apply        Terraform apply (Aurora Express)"
	@echo "  destroy      Terraform destroy (Aurora Express)"
	@echo "  install      Create Python venv and install dependencies"
	@echo "  schema       Apply schema.sql against the running cluster"
	@echo "  run-app      Run the FastAPI notes app on port 8000"
	@echo "  cli-create   Create an Aurora Express cluster with the AWS CLI only"
	@echo "  cli-delete   Delete a CLI-created cluster"
	@echo ""
	@echo "Traditional Aurora (VPC comparison):"
	@echo "  trad-init    Initialize Terraform in terraform-traditional/"
	@echo "  trad-plan    Terraform plan (traditional Aurora)"
	@echo "  trad-apply   Terraform apply (traditional Aurora)"
	@echo "  trad-destroy Terraform destroy (traditional Aurora)"
	@echo ""
	@echo "  clean        Remove local Python venv and diagram build artifacts"

init:
	cd terraform && terraform init

fmt:
	terraform fmt -recursive terraform terraform-traditional

validate:
	cd terraform && terraform validate

plan:
	cd terraform && terraform plan \
	    -var project_name=$(PROJECT) -var environment=$(ENV) -var aws_region=$(REGION)

apply:
	cd terraform && terraform apply -auto-approve \
	    -var project_name=$(PROJECT) -var environment=$(ENV) -var aws_region=$(REGION)

destroy:
	cd terraform && terraform destroy -auto-approve \
	    -var project_name=$(PROJECT) -var environment=$(ENV) -var aws_region=$(REGION)

schema:
	@cd terraform && eval "$$(terraform output -json connection_hint | jq -r 'to_entries | .[] | "export \(.key)=\(.value)"')" && \
	  export PGPASSWORD=$$(aws rds generate-db-auth-token --hostname $$DB_ENDPOINT --port 5432 --username $$DB_USER --region $$AWS_REGION) && \
	  psql "host=$$DB_ENDPOINT dbname=postgres user=$$DB_USER sslmode=verify-full sslrootcert=system" -c "CREATE DATABASE $$DB_NAME;" 2>/dev/null || true && \
	  export PGPASSWORD=$$(aws rds generate-db-auth-token --hostname $$DB_ENDPOINT --port 5432 --username $$DB_USER --region $$AWS_REGION) && \
	  psql "host=$$DB_ENDPOINT dbname=$$DB_NAME user=$$DB_USER sslmode=verify-full sslrootcert=system" -f ../python/schema.sql

install:
	cd python && python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

run-app:
	@cd terraform && eval "$$(terraform output -json connection_hint | jq -r 'to_entries | .[] | "export \(.key)=\(.value)"')" && \
	  cd ../python && . .venv/bin/activate && uvicorn app:app --port 8000

cli-create:
	CLUSTER_ID=$(PROJECT)-cli AWS_REGION=$(REGION) scripts/create-express-cluster.sh

cli-delete:
	CLUSTER_ID=$(PROJECT)-cli AWS_REGION=$(REGION) scripts/delete-express-cluster.sh

trad-init:
	cd terraform-traditional && terraform init

trad-plan:
	cd terraform-traditional && terraform plan \
	    -var aws_region=$(REGION)

trad-apply:
	cd terraform-traditional && terraform apply -auto-approve \
	    -var aws_region=$(REGION)

trad-destroy:
	cd terraform-traditional && terraform destroy -auto-approve \
	    -var aws_region=$(REGION)

clean:
	rm -rf python/.venv python/__pycache__ python/**/__pycache__ generated-diagrams
