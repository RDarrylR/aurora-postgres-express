"""Minimal connection example for Aurora PostgreSQL Express.

The express cluster is not inside a VPC. Clients connect over the internet
through the Aurora internet access gateway using TLS and an IAM auth token.

TLS is configured entirely through libpq parameters (sslmode, sslrootcert).

psycopg[binary] bundles its own OpenSSL, which does not read the macOS
Keychain or the system trust store that psql uses. We use certifi.where()
to get a portable CA bundle path that includes the Amazon Root CAs needed
for the Aurora internet access gateway. certifi is already installed as
a transitive dependency of boto3.
"""

from __future__ import annotations

import os

import boto3
import certifi
import psycopg


def build_auth_token(endpoint: str, port: int, user: str, region: str) -> str:
    """Generate a short-lived IAM authentication token for Aurora."""
    rds = boto3.client("rds", region_name=region)
    return rds.generate_db_auth_token(
        DBHostname=endpoint,
        Port=port,
        DBUsername=user,
        Region=region,
    )


def connect() -> psycopg.Connection:
    """Open a psycopg 3 connection to Aurora Express using IAM auth."""
    endpoint = os.environ["DB_ENDPOINT"]
    port = int(os.environ.get("DB_PORT", "5432"))
    user = os.environ.get("DB_USER", "postgres")
    database = os.environ.get("DB_NAME", "appdb")
    region = os.environ.get("AWS_REGION", "us-east-1")

    token = build_auth_token(endpoint, port, user, region)

    # TLS on psycopg 3 is handled by libpq, not by Python's ssl module.
    # Do NOT pass context=ssl.SSLContext here -- psycopg's "context" kwarg
    # is an AdaptContext (type-adapter registry), not an ssl.SSLContext.
    #
    # psycopg[binary] bundles its own OpenSSL which does not read the macOS
    # Keychain or the system trust store that psql uses. We point sslrootcert
    # at the certifi CA bundle (a boto3 dependency, already installed) which
    # includes the Amazon Root CAs needed for the internet access gateway.
    return psycopg.connect(
        host=endpoint,
        port=port,
        user=user,
        password=token,
        dbname=database,
        sslmode="verify-full",
        sslrootcert=certifi.where(),
        connect_timeout=10,
    )


def main() -> None:
    with connect() as conn, conn.cursor() as cur:
        cur.execute("SELECT version(), current_user, current_database();")
        version, user, database = cur.fetchone()
        print(f"Connected to {database} as {user}")
        print(f"Server: {version}")


if __name__ == "__main__":
    main()
