#!/bin/bash
# Database restore script for MediMinder PostgreSQL
# Usage: ./scripts/db-restore.sh <backup_file>
# Example: ./scripts/db-restore.sh /backups/mediminder_20260223_020000.sql.gz

set -euo pipefail

# Configuration
DB_CONTAINER="${DB_CONTAINER:-mediminder-db}"
DB_NAME="${POSTGRES_DB:-mediminder}"
DB_USER="${POSTGRES_USER:-mediminder}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2; }

if [ $# -eq 0 ]; then
    error "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lht /backups/mediminder_*.sql.gz 2>/dev/null || echo "  No backups found in /backups/"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
log "Restoring from: ${BACKUP_FILE} (${BACKUP_SIZE})"

warn "⚠️  This will DROP and recreate the '${DB_NAME}' database!"
read -p "Are you sure? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
    log "Restore cancelled."
    exit 0
fi

# Stop the backend to prevent connections
log "Stopping backend container..."
docker stop mediminder-backend 2>/dev/null || true

# Drop and recreate database
log "Dropping and recreating database..."
docker exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '${DB_NAME}' AND pid <> pg_backend_pid();
"
docker exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"
docker exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

# Restore
log "Restoring database..."
if gunzip -c "${BACKUP_FILE}" | docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" > /dev/null 2>&1; then
    log "Database restored successfully!"
else
    error "Restore failed!"
    exit 1
fi

# Restart backend
log "Starting backend container..."
docker start mediminder-backend 2>/dev/null || true

log "Restore process completed."
