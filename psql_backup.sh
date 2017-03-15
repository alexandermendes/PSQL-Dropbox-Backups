#!/bin/bash
#
# PSQL-Dropbox-Backups
#
# The script stores gzipped backups of each database into date-based directories.
# As well as being stored locally these directories will be uploaded to Dropbox,
# assuming you have set tht path to a Dropbox-Uploader script. Expired directories
# are removed periodically, both locally and from Dropbox.
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

# Which day to take the weekly backup from (1-7 = Monday-Sunday).
DAY_OF_WEEK_TO_KEEP=7

# Number of days to keep daily backups.
DAYS_TO_KEEP=7

# How many weeks to keep weekly backups.
WEEKS_TO_KEEP=2

# This dir must be writable by the user the script is running as.
BACKUP_DIR=/srv/backups/postgres/

# Output file format [c|t|p|d] (custom, tar, plain text, directory)
BACKUP_FORMAT=p

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

if [ ! $UPLOAD_DESTINATION ]; then
    UPLOAD_DESTINATION="/backups/";
fi

export PGPASSWORD="$PASSWORD";


#############################
##### START THE BACKUPS #####
#############################

function upload_to_dropbox()
{
    if [ $DROPBOX_UPLOADER ]; then
        BACKUP_PATH=$1
        TAIL=$2

        REMOTE_FILE=$UPLOAD_DESTINATION$TAIL

        $DROPBOX_UPLOADER upload $BACKUP_PATH $REMOTE_FILE
    fi
}


function perform_backups()
{
    SUFFIX=$1
    TAIL_DIR="`date +\%Y-\%m-\%d`$SUFFIX/"
    FINAL_BACKUP_DIR=$BACKUP_DIR"$TAIL_DIR"

    FULL_BACKUP_QUERY="select datname from pg_database where not datistemplate and datallowconn order by datname;"

    if ! mkdir -p $FINAL_BACKUP_DIR; then
        echo "Cannot create backup directory $FINAL_BACKUP_DIR, check your permissions!" 1>&2
        exit 1;
    fi;

    for DATABASE in `psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$FULL_BACKUP_QUERY" postgres`; do
        echo -e "\nBacking up $DATABASE to $FINAL_BACKUP_DIR"

        if ! pg_dump -F "$BACKUP_FORMAT" -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip > $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress; then
            echo "[!!ERROR!!] Failed to produce backup database $DATABASE" 1>&2
        else
            mv $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress $FINAL_BACKUP_DIR"$DATABASE".sql.gz

            upload_to_dropbox $FINAL_BACKUP_DIR"$DATABASE".sql.gz $TAIL_DIR"$DATABASE".sql.gz
        fi

    done
}

echo -e "\nRemoving expired backups"
echo -e "--------------------------------------------\n"

DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
EXPIRED_DAYS=`expr $((($WEEKS_TO_KEEP * 7) + 1))`
DAY_OF_MONTH=`date +%d`

if [ $DAY_OF_MONTH -eq 1 ]; then
    for FILE in $(find $BACKUP_DIR -maxdepth 1 -name "*-monthly"); do
        EXPIRED_DIR=${FILE##*/}
        rm -rf $FILE

        if [ $DROPBOX_UPLOADER ]; then
            $DROPBOX_UPLOADER delete $UPLOAD_DESTINATION$EXPIRED_DIR
        fi
    done
fi

if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ]; then
    for FILE in $(find $BACKUP_DIR -maxdepth 1 -mtime +$EXPIRED_DAYS -name "*-weekly"); do
        EXPIRED_DIR=${FILE##*/}
        rm -rf $FILE

        if [ $DROPBOX_UPLOADER ]; then
            $DROPBOX_UPLOADER delete $UPLOAD_DESTINATION$EXPIRED_DIR
        fi
    done
fi

for FILE in $(find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*-daily"); do
    EXPIRED_DIR=${FILE##*/}
    rm -rf $FILE

    if [ $DROPBOX_UPLOADER ]; then
        $DROPBOX_UPLOADER delete $UPLOAD_DESTINATION$EXPIRED_DIR
    fi
done


echo -e "\nPerforming backups"
echo "--------------------------------------------"

if [ $DAY_OF_MONTH -eq 1 ]; then
    perform_backups "-monthly"

    exit 0;
fi

if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ]; then
    perform_backups "-weekly"

    exit 0;
fi

perform_backups "-daily"

echo -e "\nAll databases backed up!"
