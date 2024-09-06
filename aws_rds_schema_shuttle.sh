#!/bin/bash
set -e
#!Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

#!Function for print colored messages
print_color() {
    color=$1
    message=$2
    echo "${color}${message}${RESET}"
}



cat <<EOF
 ____       _                          
/ ___|  ___| |__   ___ _ __ ___   __ _ 
\___ \ / __| '_ \ / _ \ '_ (_ \ /  _) |
 ___) | (__| | | |  __/ | | | | | (_| |
|____/ \___|_| |_|\___|_| |_| |_|\__,_|
/ ___|| |__  _   _| |_| |_| | ___      
\___ \| '_ \| | | | __| __| |/ _ \     
 ___) | | | | |_| | |_| |_| |  __/     
|____/|_| |_|\__,_|\__|\__|_|\___|     

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

timestamp=$(date "+%Y-%m-%d %H:%M:%S")
BACKUP_DIR="./Backup/Dumper_${DB_NAME}_$timestamp"
LOG_FILE="./Backup/DumperLogs/mydumper_$timestamp.log"

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
echo

#!Prompt user to continue or exit
read -p "Do you want to continue with the restore process? (y/n): " continue_restore
if [[ $continue_restore != "y" && $continue_restore != "Y" ]]; then
    echo "Exiting script. Goodbye!"
    exit 0
fi

#!Prompt user for destination DB credentials
echo -e "\n=== Destination Database Details ==="
get_user_input "Enter destination DB host" DEST_DB_HOST "localhost"
get_user_input "Enter destination DB user" DEST_DB_USER "root"
get_user_input "Enter destination DB password" DEST_DB_PASSWORD ""
get_user_input "Enter destination DB name" DEST_DB_NAME "mysql"
get_user_input "Enter destination DB port" DEST_DB_PORT "3306"

#!Print destination credentials
print_credentials "$DEST_DB_HOST" "$DEST_DB_USER" "$DEST_DB_NAME" "$DEST_DB_PORT"

#!myloader log file
RESTORE_LOG_FILE="./Backup/LoaderLogs/myloader_$timestamp.log"

#!myloader
echo -e "\nStarting restore process..."
echo
sudo time myloader \
    --host="$DEST_DB_HOST" \
    --user="$DEST_DB_USER" \
    --password="$DEST_DB_PASSWORD" \
    --port="$DEST_DB_PORT" \
    --database="$DEST_DB_NAME" \
    --directory="$BACKUP_DIR" \
    --threads=16 \
    --verbose=3 \
    --skip-definer \
    --ignore-errors -v \
    2>&1 | tee -a "$RESTORE_LOG_FILE"

if [ $? -eq 0 ]; then
    echo -e ${GREEN}"DB Restored Successfully!!\n" 
    echo -e "Backups restored from : ${BLUE}$BACKUP_DIR${RESET}\n"
    echo "Restored DB name: ${YELLOW}$DEST_DB_NAME${RESET}"
    echo
    exit 1
else
    echo -e ${RED}"DB Restore Failed!!\n"
    echo "Please check the log file :${YELLOW}$RESTORE_LOG_FILE${RESET}"
    exit 1
fi

echo
echo -e "\nChecking the size of the restored database...\n"
mysql -h "$DEST_DB_HOST" -u "$DEST_DB_USER" -p"$DEST_DB_PASSWORD" -P "$DEST_DB_PORT" -e "SELECT table_schema AS 'Database',ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS 'Size_GB' FROM information_schema.tables WHERE table_schema = '$DEST_DB_NAME' GROUP BY table_schema;" | tee -a "$LOG_FILE"
echo
echo

echo -e "\nGoodbye! さようなら! अलविदा! !مع السلامة"
exit 0