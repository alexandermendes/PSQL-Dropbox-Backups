# PSQL-Dropbox-Backups

BASH script to save date-based backups locally and also upload them to Dropbox.

The script Goes through each database and saves a gzipped backup into a
date-based directory, also duplicating this directory on Dropbox.


## Usage

Download and configure [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader),
then download and configure this script by editing the variables in the
`CONFIGURATION` section.

Remember to make the script executable:

``` bash
chmod +x psql_backups.sh
```

If you want the script to run daily:

``` bash
mv psql_backups.sh /etc/cron.daily/psql_backups
```
