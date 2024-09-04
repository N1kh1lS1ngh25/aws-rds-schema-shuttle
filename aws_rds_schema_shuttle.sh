#!/bin/bash
set -e #to exit immediately if any command exits with a non-0 status

#function to prompt user for input with a default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local response

    read -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

#function for yes/no confirmation
confirm() {
    local prompt="$1"
    local response

    while true; do
        read -p "$prompt (y/n): " response
        case $response in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
}

# Function to set directory permissions
set_directory_permissions() {
    local dir="$1"
    local user="$2"
    sudo chown -R "$user:$user" "$dir"
    sudo chmod 755 "$dir"
    sudo find "$dir" -type f -exec chmod 644 {} \;
}

# Prompt for source RDS details
echo "Enter source RDS details:"
SRC_DB_HOST=$(prompt_with_default "Enter source DB host" "localhost")
SRC_DB_USER=$(prompt_with_default "Enter source DB user" "root")
SRC_DB_PASSWORD=$(prompt_with_default "Enter source DB password" "")
SRC_DB_NAME=$(prompt_with_default "Enter source DB name" "mydb")
SRC_DB_PORT=$(prompt_with_default "Enter source DB port" "3306")

# Prompt for backup directory and log file
BACKUP_DIR=$(prompt_with_default "Enter backup directory" "./Backup/Dumper")
LOG_FILE=$(prompt_with_default "Enter log file path" "/tmp/rds_backup_restore.log")

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup process
echo "Starting backup process..."
if ! mydumper \
    --host="$SRC_DB_HOST" \
    --user="$SRC_DB_USER" \
    --password="$SRC_DB_PASSWORD" \
    --port="$SRC_DB_PORT" \
    --database="$SRC_DB_NAME" \
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

echo "Backup completed successfully. Backup files are located in $BACKUP_DIR."

# Verify backup files
if ! ls "$BACKUP_DIR"/*.sql.gz >/dev/null 2>&1; then
    echo "No .sql.gz files found in backup directory. Backup may have failed."
    exit 1
fi