#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Database connection details
DB_HOST="db_host"
DB_USER="db_user_with_privs"
DB_PASSWORD="db_password"
DB_NAME="dn_name"
DB_PORT=3306

# Backup details
BACKUP_DIR="./Backup/Dumper"
LOG_FILE="/tmp/mydumper_$(date +%Y%m%d_%H%M%S).log"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR" || {
    echo "Failed to create backup directory. Please check permissions."
    exit 1
}
chmod 755 "$BACKUP_DIR"

# Check if the directory is writable
if [ ! -w "$BACKUP_DIR" ]; then
    echo "Backup directory is not writable. Please check permissions."
    exit 1
fi

# Run mydumper with explicit connection details
echo "Starting backup process..."
if ! mydumper \
    --host="$DB_HOST" \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    --port="$DB_PORT" \
    --database="$DB_NAME" \
    --outputdir="$BACKUP_DIR" \
    --rows=500000 \
    --triggers \
    --routines \
    --events \
    --compress \
    --threads=16 \
    --compress-protocol \
    --verbose=3 \
    2>&1 | tee -a "$LOG_FILE"; then
    echo "Backup failed. Check the log file at $LOG_FILE for details."
    exit 1
fi

# Verify backup files
echo "Verifying backup files..."
if ! ls "$BACKUP_DIR"/*.sql.gz >/dev/null 2>&1; then
    echo "No .sql.gz files found in backup directory. Backup may have failed."
    exit 1
fi

# Check for any pipes
if find "$BACKUP_DIR" -type p | grep -q .; then
    echo "Warning: Named pipes found in backup directory. This is unexpected."
    find "$BACKUP_DIR" -type p
fi

# Check file types
echo "Checking file types in backup directory:"
file "$BACKUP_DIR"/*

echo "Backup completed successfully. Backup files are located in $BACKUP_DIR."
