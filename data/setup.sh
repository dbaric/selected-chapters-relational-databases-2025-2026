#!/usr/bin/env bash
set -euo pipefail

DB_USER="unist_rezervacije"
DB_NAME="unist_rezervacije"
DB_HOST="localhost"
DB_PORT="5432"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

psql() {
    command psql -v ON_ERROR_STOP=1 -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" "$@"
}

echo "==> nuke..."
psql -f "$DIR/nuke.sql"

echo "==> schema..."
psql -f "$DIR/schema.sql"

echo "==> seed..."
psql -f "$DIR/seed.sql"

echo "==> done."
