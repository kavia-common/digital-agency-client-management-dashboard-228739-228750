#!/bin/bash
set -euo pipefail

# Idempotent schema initialization for the project_management_database container.
# This script is designed to be safe to run repeatedly at container startup.

DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

export PGPASSWORD="${DB_PASSWORD}"

echo "Initializing schema in PostgreSQL (${DB_NAME})..."

# Create extensions (uuid generation)
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# Tables
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE TABLE IF NOT EXISTS users (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), email TEXT NOT NULL, password_hash TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE TABLE IF NOT EXISTS clients (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT NOT NULL, contact_email TEXT, phone TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE TABLE IF NOT EXISTS projects (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), client_id UUID NOT NULL, name TEXT NOT NULL, status TEXT NOT NULL, budget NUMERIC, start_date DATE, due_date DATE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), CONSTRAINT projects_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE);"
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE TABLE IF NOT EXISTS user_settings (user_id UUID PRIMARY KEY, theme TEXT NOT NULL DEFAULT 'light', CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE);"

# Constraints / Indexes
# Users email uniqueness (case-insensitive).
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique_idx ON users (LOWER(email));"

# Useful indexes
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE INDEX IF NOT EXISTS clients_name_idx ON clients (name);"
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE INDEX IF NOT EXISTS projects_client_id_idx ON projects (client_id);"
${PG_BIN}/psql -h localhost -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -c "CREATE INDEX IF NOT EXISTS projects_status_idx ON projects (status);"

# Optional: enforce email uniqueness even if a plain unique constraint exists later.
# Kept as index-only to be idempotent and avoid ALTER TABLE error handling.

echo "Schema initialization complete."
