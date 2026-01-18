#!/usr/bin/env bash
set -euo pipefail

# Persistent storage defaults (Render Persistent Disk)
DATA_DIR="${DATA_DIR:-/var/data}"
DB_PATH="${SQLITE_DB_PATH:-${DATA_DIR}/unintend.db}"

# Ensure defaults exist for uploads + database
export UPLOADS_DIR="${UPLOADS_DIR:-${DATA_DIR}/uploads}"
mkdir -p "${UPLOADS_DIR}"

# If DATABASE_URL isn't set, point it at the persistent SQLite file.
if [[ -z "${DATABASE_URL:-}" ]]; then
  export DATABASE_URL="sqlite:///${DB_PATH}"
fi

python scripts/init_persistent_storage.py

exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --proxy-headers
