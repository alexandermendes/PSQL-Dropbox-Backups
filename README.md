# PSQL-Dropbox-Backups

BASH script to save date-based backups locally and also upload them to Dropbox.


## Installation

Download and configure [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader),
making sure to grant full Dropbox permissions, otherwise this script won't be able to
delete previous backups according to your configuration details.

Next, download this repository and make [psql_backup.sh](psql_backup.sh) executable:

``` bash
git clone https://github.com/alexandermendes/PSQL-Dropbox-Backups
cd PSQL-Dropbox-Backups/
chmod +x psql_backup.sh
```


## Configuration

Edit the configuration variables at the top of the script:

``` bash
# Optional hostname to adhere to pg_hba policies (default is "localhost").
HOSTNAME=

# Optional username to connect to database as (default is "postgres").
USERNAME=

# Optional password for the above user.
PASSWORD=

# Which day to take the weekly backup from (1-7 = Monday-Sunday)
DAY_OF_WEEK_TO_KEEP=7

# How many weeks to keep weekly backups
DAYS_TO_KEEP=7

# How many weeks to keep weekly backups
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
