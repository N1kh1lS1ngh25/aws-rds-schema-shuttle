#!/bin/bash
set -e
cat << EOF

  _________      .__                                      _________.__            __    __  .__          
 /   _____/ ____ |  |__   ____   _____ _____             /   _____/|  |__  __ ___/  |__/  |_|  |   ____  
 \_____  \_/ ___\|  |  \_/ __ \ /     \\__  \    ______  \_____  \ |  |  \|  |  \   __\   __\  | _/ __ \ 
 /        \  \___|   Y  \  ___/|  Y Y  \/ __ \_ /_____/  /        \|   Y  \  |  /|  |  |  | |  |_\  ___/ 
/_______  /\___  >___|  /\___  >__|_|  (____  /         /_______  /|___|  /____/ |__|  |__| |____/\___  >
        \/     \/     \/     \/      \/     \/                  \/      \/                            \/ 

EOF
sleep 3

#!prompt user for input with default values
get_user_input() {
    local prompt="$1"
    local variable_name="$2"
    local default_value="$3"

    read -p "$prompt [$default_value]: " user_input
   
    eval "$variable_name=\"${user_input:-$default_value}\""
}
#!check directory
check_directory() {
    local dir="$1"
    mkdir -p "$dir" || {
        echo "\nFailed to create directory: $dir. Please check permissions.\n"
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

#!check and report mydumper errors
check_mydumper_error() {
    local exit_code=$1
    local log_file=$2

    if [ $exit_code -ne 0 ]; then
        echo "Backup failed with exit code $exit_code. Analyzing error..."

        # Check for common error patterns
        if grep -q "Access denied" "$log_file"; then
            echo "Error: Access denied. Please check your database credentials and permissions."
        elif grep -q "Can't connect to MySQL server" "$log_file"; then
            echo "Error: Unable to connect to MySQL server. Please check if the server is running and the host/port are correct."
        elif grep -q "Unknown database" "$log_file"; then
            echo "Error: Unknown database. Please check if the database name is correct."
        elif grep -q "Couldn't execute 'FLUSH TABLES WITH READ LOCK'" "$log_file"; then
            echo "Error: Unable to acquire necessary locks. The user may lack RELOAD privilege or there might be long-running queries blocking the lock."
        else
            echo "Unknown error occurred. Please check the log file for more details."
        fi

        echo "Last 10 lines of the log file:"
        tail -n 10 "$log_file"

        exit 1
    fi
}

#!Prints credentials to user
print_credentials() {
    local host="$1"
    local user="$2"
    local db="$3"
    local port="$4"

    echo -e "\n==== Database Credentials ===="
    echo "Host: $host"
    echo "User: $user"
    echo "Database: $db"
    echo "Port: $port"
    echo "==============================="
}

#!Prompt user for source DB input
echo -e "\n=== Source Database Details ==="
get_user_input "Enter DB host" DB_HOST "localhost"
get_user_input "Enter DB user" DB_USER "root"
get_user_input "Enter DB password" DB_PASSWORD ""
get_user_input "Enter DB name" DB_NAME "mysql"
get_user_input "Enter DB port" DB_PORT "3306"
get_user_input "Enter myloader user" MYLOADER_USER "ubuntu"


#!Print source credentials
print_credentials "$DB_HOST" "$DB_USER" "$DB_NAME" "$DB_PORT"

#!Backup directory details
BACKUP_DIR="./Backup/Dumper_${DB_NAME}_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="./Backup/DumperLogs/mydumper_$(date +%Y%m%d_%H%M%S).log"

echo -e "\nBackup will be stored in: $BACKUP_DIR"

#!Verify backup and log directories
check_directory "$BACKUP_DIR"
check_directory "$(dirname "$LOG_FILE")"

sleep 2
echo -e "\nStarting backup process..."
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
    2>&1 | tee -a "$LOG_FILE"

#!Catci for mydumper errors
check_mydumper_error $? "$LOG_FILE"

# Change ownership of the backup directory and its contents
echo -e "\nFixing permissions and ownership for backup files and directory...\n"
sudo chown -R "$MYLOADER_USER:$MYLOADER_USER" "$BACKUP_DIR"
chmod 755 "$BACKUP_DIR"
find "$BACKUP_DIR" -type f -exec chmod 644 {} \;
echo -e "\nPermissions and ownership updated on $BACKUP_DIR\n"
echo "Directory permissions:"
ls -ld "$BACKUP_DIR"
echo -e "Backup completed successfully. Backup files are located in $BACKUP_DIR."
echo

