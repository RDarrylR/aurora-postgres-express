# Python Samples

Targets Python 3.14.

## Install

```bash
python3.14 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Environment

Populate these from the Terraform outputs:

```bash
export DB_ENDPOINT=...   # cluster_endpoint output
export DB_NAME=appdb
export DB_USER=postgres
export AWS_REGION=us-east-1
```

## Run

```bash
# Smoke test the connection
python connect.py

# Apply the schema (one-time, with admin credentials)
psql "host=$DB_ENDPOINT dbname=$DB_NAME user=$DB_USER sslmode=verify-full sslrootcert=system" \
     -f schema.sql

# Exercise CRUD
python crud.py

# Run the FastAPI app
uvicorn app:app --port 8000
```
