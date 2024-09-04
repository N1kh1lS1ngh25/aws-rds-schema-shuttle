#!/bin/bash
# Destination database connection details
DEST_DB_HOST="db_host"
DEST_DB_USER="db_user_with_privs"
DEST_DB_PASSWORD="db_password"
DEST_DB_NAME="dn_name"
DEST_DB_PORT=3306

# Backup details
BACKUP_DIR="./Backup/Dumper"
LOG_FILE="./MyLoader/myloader.log"

# Ensure the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory does not exist. Please check the path."
    exit 1
fi

# Check if the directory is readable
if [ ! -r "$BACKUP_DIR" ]; then
    echo "Backup directory is not readable. Please check permissions."
    exit 1
fi

# Run myloader with explicit connection details
echo "Starting restore process..."
sudo time myloader \
    --host="$DEST_DB_HOST" \
    --user="$DEST_DB_USER" \
    --password="$DEST_DB_PASSWORD" \
    --port="$DEST_DB_PORT" \
    --database="$DEST_DB_NAME" \
    --directory="$BACKUP_DIR" \
    --threads=16 \
    --verbose=3 \
    2>&1 | tee -a "$LOG_FILE"

# Check if myloader executed successfully
if [ $? -eq 0 ]; then
    echo "Restore completed successfully. Backup files were restored from $BACKUP_DIR to $DEST_DB_NAME on $DEST_DB_HOST."
else
    echo "Restore failed. Check the log file at $LOG_FILE for details."
    exit 1
fi

# Check the size of the restored database
echo "Checking the size of the restored database..."
mysql -h "$DEST_DB_HOST" -u "$DEST_DB_USER" -p"$DEST_DB_PASSWORD" -P "$DEST_DB_PORT" -e "
SELECT table_schema AS 'Database',
       ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS 'Size_GB'
FROM information_schema.tables
WHERE table_schema = '$DEST_DB_NAME'
GROUP BY table_schema;
" | tee -a "$LOG_FILE"

# Check if the size query executed successfully
if [ $? -eq 0 ]; then
    echo "Database size checked successfully. See the log file at $LOG_FILE for details."
else
    echo "Failed to check the database size. Check the log file at $LOG_FILE for details."
    exit 1
fi
