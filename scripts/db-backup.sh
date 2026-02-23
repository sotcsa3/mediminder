#!/bin/bash
# Database backup script for MediMinder PostgreSQL
# Usage: ./scripts/db-backup.sh [backup_dir]
# Cron example (daily at 2 AM): 0 2 * * * /app/scripts/db-backup.sh /backups

set -euo pipefail

# Configuration
BACKUP_DIR="${1:-/backups}"
DB_CONTAINER="${DB_CONTAINER:-mediminder-db}"
DB_NAME="${POSTGRES_DB:-mediminder}"
DB_USER="${POSTGRES_USER:-mediminder}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/mediminder_${TIMESTAMP}.sql.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BACKUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2; }

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

log "Starting database backup..."
log "Target: ${BACKUP_FILE}"

# Perform backup via docker exec
if docker exec "${DB_CONTAINER}" pg_dump -U "${DB_USER}" "${DB_NAME}" | gzip > "${BACKUP_FILE}"; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log "Backup completed successfully (${BACKUP_SIZE})"
else
    error "Backup failed!"
    rm -f "${BACKUP_FILE}"
    exit 1
fi

# Verify backup is not empty
if [ ! -s "${BACKUP_FILE}" ]; then
    error "Backup file is empty!"
    rm -f "${BACKUP_FILE}"
    exit 1
fi

# Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "mediminder_*.sql.gz" -mtime +${RETENTION_DAYS} -delete -print | wc -l)
if [ "${DELETED_COUNT}" -gt 0 ]; then
    log "Deleted ${DELETED_COUNT} old backup(s)"
fi

# List current backups
TOTAL_BACKUPS=$(find "${BACKUP_DIR}" -name "mediminder_*.sql.gz" | wc -l)
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
log "Total backups: ${TOTAL_BACKUPS} (${TOTAL_SIZE})"

log "Backup process completed."
