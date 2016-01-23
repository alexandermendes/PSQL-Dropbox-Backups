# PSQL-Dropbox-Backups

BASH script to store date-based backups both locally and on Dropbox.


## Installation

Download and configure [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader).
Make sure that you grant full Dropbox permissions, otherwise this script won't be able to
remove any expired backups.

Next, download this repository and make [psql_backup.sh](psql_backup.sh) executable:

``` bash
git clone https://github.com/alexandermendes/PSQL-Dropbox-Backups
cd PSQL-Dropbox-Backups/
chmod +x psql_backup.sh
```


## Configuration

The following configuration variables can be found at the top of the script:

``` bash
# Optional hostname to adhere to pg_hba policies (default is "localhost").
HOSTNAME=

# Optional username to connect to database as (default is "postgres").
USERNAME=

# Optional password for the above user.
PASSWORD=

# Which day to take the weekly backup from (1-7 = Monday-Sunday).
DAY_OF_WEEK_TO_KEEP=7

# Number of days to keep daily backups.
DAYS_TO_KEEP=7

# How many weeks to keep weekly backups.
WEEKS_TO_KEEP=4

# This dir must be writable by the user the script is running as.
BACKUP_DIR=/srv/backups/postgres/

# Path to the executable dropbox_uploader script.
DROPBOX_UPLOADER=/opt/bin/dropbox_uploader.sh

# Dropbox location to upload the directories (default is "/backups/").
UPLOAD_DESTINATION=/postgres/backups/
```


## Usage

You can execute the script by running:

``` bash
./psql_backup.sh
```

To schedule the script to exeucte daily you can do this:

``` bash
mv psql_backup.sh /etc/cron.daily/psql_backup
```
