echo "
  _________      .__                                      _________.__            __    __  .__          
 /   _____/ ____ |  |__   ____   _____ _____             /   _____/|  |__  __ ___/  |__/  |_|  |   ____  
 \_____  \_/ ___\|  |  \_/ __ \ /     \\__  \    ______  \_____  \ |  |  \|  |  \   __\   __\  | _/ __ \ 
 /        \  \___|   Y  \  ___/|  Y Y  \/ __ \_ /_____/  /        \|   Y  \  |  /|  |  |  | |  |_\  ___/ 
/_______  /\___  >___|  /\___  >__|_|  (____  /         /_______  /|___|  /____/ |__|  |__| |____/\___  >
        \/     \/     \/     \/      \/     \/                  \/      \/                            \/
"

#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.


# Database connection details:
DB_HOST="your_db_host"
DB_USER="db_user_with_privs"
DB_PASSWORD="db_password"
DB_NAME="dn_name"
DB_PORT=3306
MyDumper_User="ubuntu"                   #give user name as per use-case


#function to check  direcotry exists or not.
check_directory() {
    local dir="$1"
    mkdir -p "$dir" || {
        echo
        echo "Failed to create directory: $dir. Please check permissions.\n"
        exit 1
    }
    chmod 755 "$dir"
    if [ ! -w "$dir" ]; then
        echo
        echo "Directory is not writable: $dir. Please check permissions."
        echo
        exit 1
    fi
}

#! Backup details:
BACKUP_DIR="./Backup/Dumper_${DB_NAME}_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="./Backup/DumperLogs/mydumper_$(date +%Y%m%d_%H%M%S).log"


# Check if the directory exists or not:
check_directory "$BACKUP_DIR"
check_directory "$(dirname "$LOG_FILE")"

# Run mydumper with explicit connection details
echo "Starting backup process..."
echo
mydumper \
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
    --no-locks \
    2>&1 | tee -a "$LOG_FILE";


#! Change ownership of the backup directory and its contents
echo
echo "Fixing permissions and ownership for backup files and directory..."
echo

chown -R "$MYLOADER_USER:$MYLOADER_USER" "$BACKUP_DIR"

#! Set directory permissions
chmod 755 "$BACKUP_DIR"

#! Set file permissions
find "$BACKUP_DIR" -type f -exec chmod 644 {} \;
echo
echo "Permissions and ownership updated."
echo

#! Display debug information
echo "Directory permissions:"
ls -ld "$BACKUP_DIR"
echo "File permissions (sample):"
ls -l "$BACKUP_DIR" | head -n 5

echo
echo
echo "Backup completed successfully. Backup files are located in $BACKUP_DIR."
