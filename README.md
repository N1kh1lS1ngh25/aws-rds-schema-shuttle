<img src = "https://skillicons.dev/icons?i=aws"/> <img src = "https://skillicons.dev/icons?i=bash"/>

# What is Schema-Shuttle ?

This is a Bash script which is designed to facilitate the backup and restoration of MySQL databases using `mydumper` and `myloader`. It provides a user-friendly interface to input database credentials, manage backup directories, and handle errors effectively. The script also incorporates color-coded output for better readability.

MyDumper is a MySQL Logical Backup Tool. It has 2 tools:

* `mydumper` which is responsible to export a consistent backup of MySQL databases
* `myloader` reads the backup from mydumper, connects to the destination database and imports the backup.

Both tools use multithreading capabilities.<br>
```
MyDumper is Open Source and maintained by the community, it is not a Percona, MariaDB or MySQL product.
```


## Why to use MyDumper and MyLoader ?
* **Parallelism** (hence, speed) and performance (avoids expensive character set conversion routines, efficient code overall)
* **Easier to manage output** (separate files for tables, dump metadata, etc, easy to view/parse data)
* **Consistency** - maintains snapshot across all threads, provides accurate master and slave log positions, etc
* **Manageability** - supports PCRE for specifying database and tables inclusions and exclusions
  
## More About MyDumper and MyLoader :
* **MyDumper Official Documentation**<br>
    [Official Documentation](https://mydumper.github.io/mydumper/docs/html/index.html)
* **MyDumper Installation Guide**<br>
    [Official Installation Guide](https://github.com/mydumper/mydumper?tab=readme-ov-file)
* **MyDumper Usage**<br>
    [usage guide to MyDumper](https://mydumper.github.io/mydumper/docs/html/mydumper_usage.html)
## Features
- **User Input**: Prompts users for source and destination database details with default values.
- **Backup Process**: Utilizes `mydumper` to create backups of specified databases.
- **Error Handling**: Analyzes `mydumper` errors and provides informative messages.
- **Permission Management**: Adjusts file and directory permissions for security.
- **Restore Process**: Uses `myloader` to restore backups to a specified database.
- **Logging**: Maintains logs of both backup and restore processes for troubleshooting.
- **Color-Coded Output**: Enhances user experience with colored messages.

## Prerequisites

- **Bash**: Ensure you have a Bash shell available.
- **mydumper**: Install `mydumper` for backup operations.
- **myloader**: Install `myloader` for restoration operations.
- **MySQL**: Ensure you have MySQL server installed and running.

## Installation and Usage

1. Clone the repository or [download the script](https://github.com/N1kh1lS1ngh25/aws-rds-schema-shuttle/releases/download/v1.0/aws_rds_schema_shuttle.sh).
2. **Make the script executable:**
   ```bash
   chmod +x aws_rds_schema_shuttl.sh
3. **Run the script**
   ```bash
    ./aws_rds_schema_shuttle.sh
4. **Follow the on-screen instructions** to input database credentials and manage backups and restores.
   * The script will prompt for the following details:
   * Source Database Host (default: localhost)
   * Source Database User (default: root)
   * Source Database Password (default: empty)
   * Source Database Name (default: mysql)
   * Source Database Port (default: 3306)
   * MyLoader User (default: ubuntu)
  
5. **Backup Directory:** The script will create a backup directory in the format `YYYY-MM-DD_HH-` in the `./Backup/ directory`.
   * It will also create a log file for the backup process as `./Backup/DumperLogs/logname_YYYY-MM-DD_HH.log`.
   * 
6. **Restore Process:** 
   * After the backup, you will be prompted to continue with the restore process
   * If you choose to proceed, you will need to enter destination database details similar to the source.
  
7. The script will output the success or failure of the restore process and provide the location of the log file.

## Error Messages
The script provides specific error messages based on common issues encountered during backup and restore operations, including:
* Access denied errors
* Connection issues with MySQL server
* Unknown database errors
* Lock acquisition failures

# Acknowledgments
* Thanks to the developers of mydumper and myloader for their excellent tools.
* Special thanks to the open-source community for their contributions.


**Notes:**
```
This script is intended for use in a controlled environment and may require adjustments for production use cases.
```
```****
The `README.md` file is structured to provide clear and concise information about thescript, making it easy for users to understand its purpose and how to use it effectively.
```
```
Feel free to modify any sections to better fit your project's specifics or to add additional information as needed.
```