#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

# Backup directory
BACKUP_DIR="./Backup/Dumper"

# User who will run myloader (change this to the appropriate user)
MYLOADER_USER="youruser_name"

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

echo "Fixing permissions and ownership for backup files and directory..."

# Change ownership of the backup directory and its contents
chown -R "$MYLOADER_USER:$MYLOADER_USER" "$BACKUP_DIR"

# Set directory permissions
chmod 755 "$BACKUP_DIR"

# Set file permissions
find "$BACKUP_DIR" -type f -exec chmod 644 {} \;
echo "Permissions and ownership updated."

# Verify backup files
echo "Verifying backup files..."
if ! find "$BACKUP_DIR" -name "*.sql.gz" -readable | grep -q .; then
    echo "No readable .sql.gz files found in backup directory. Please check the directory contents."
    exit 1
fi

# Display debug information
echo "Directory permissions:"
ls -ld "$BACKUP_DIR"
echo "File permissions (sample):"
ls -l "$BACKUP_DIR" | head -n 5

echo "Permission fix completed. Files should now be accessible for myloader."