#!/bin/bash
#
# PSQL-Dropbox-Backups
#
# Goes through each database and saves a gzipped backup into a date-based directory.
# The backup structure created on the server is duplicated on Dropbox.
#
# Sources:
# https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux
# https://github.com/andreafabrizi/Dropbox-Uploader


#############################
####### CONFIGURATION #######
#############################

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


#############################
######### INITIALISE ########
#############################

if [ ! $HOSTNAME ]; then
    HOSTNAME="localhost"
fi;

if [ ! $USERNAME ]; then
    USERNAME="postgres"
fi;

export PGPASSWORD="$PASSWORD";


#############################
##### START THE BACKUPS #####
#############################

function upload_to_dropbox()
{
    BACKUP_PATH=$1
    TAIL=$2

    if [ ! $UPLOAD_DESTINATION ]; then
        UPLOAD_DESTINATION="/backups/";
    fi

    REMOTE_FILE=$UPLOAD_DESTINATION$TAIL

    $DROPBOX_UPLOADER upload $BACKUP_PATH $REMOTE_FILE
    echo -e "\n"
}


function perform_backups()
{
    SUFFIX=$1
    TAIL_DIR="`date +\%Y-\%m-\%d`$SUFFIX/"
    FINAL_BACKUP_DIR=$BACKUP_DIR"$TAIL_DIR"

    echo "Making backup directory $FINAL_BACKUP_DIR"

    if ! mkdir -p $FINAL_BACKUP_DIR; then
        echo "Cannot create backup directory $FINAL_BACKUP_DIR" 1>&2
        exit 1;
    fi;

    FULL_BACKUP_QUERY="select datname from pg_database where not datistemplate and datallowconn order by datname;"

    echo -e "\nPerforming backups"
    echo -e "--------------------------------------------\n"

    for DATABASE in `psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$FULL_BACKUP_QUERY" postgres`; do
        echo "Backing up $DATABASE"

        if ! pg_dump -Fp -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip > $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress; then
            echo "[!!ERROR!!] Failed to produce backup database $DATABASE" 1>&2
        else
            mv $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress $FINAL_BACKUP_DIR"$DATABASE".sql.gz

            echo $TAIL_DIR"$DATABASE".sql.gz
            upload_to_dropbox $FINAL_BACKUP_DIR"$DATABASE".sql.gz $TAIL_DIR"$DATABASE".sql.gz
        fi

    done

    echo -e "All databases backed up!"
}


# MONTHLY BACKUPS

DAY_OF_MONTH=`date +%d`

if [ $DAY_OF_MONTH -eq 1 ];
then
    # Delete all expired monthly directories
    find $BACKUP_DIR -maxdepth 1 -name "*-monthly" -exec rm -rf '{}' ';'

    perform_backups "-monthly"

    exit 0;
fi


# WEEKLY BACKUPS

DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
EXPIRED_DAYS=`expr $((($WEEKS_TO_KEEP * 7) + 1))`

if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ];
then
    # Delete all expired weekly directories
    find $BACKUP_DIR -maxdepth 1 -mtime +$EXPIRED_DAYS -name "*-weekly" -exec rm -rf '{}' ';'

    perform_backups "-weekly"

    exit 0;
fi


# DAILY BACKUPS

# Delete daily backups 7 days old or more
find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*-daily" -exec rm -rf '{}' ';'

perform_backups "-daily"
