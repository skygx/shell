
#!/bin/bash

# This script will backup a MySQL database and upload it to an S3 bucket

# Set the date format for the backup filename
DATE=$(date +"%Y-%m-%d")
OLDDATE=$(date +"%Y-%m-%d" -d '-7 days')

# Set the name of the database to backup
DB_NAME="my_database"

# Set the S3 bucket name and path
S3_BUCKET="my_bucket"
S3_PATH="backups/mysql"

# Set the MySQL username and password
MYSQL_USER="root"
MYSQL_PASSWORD="root"

BACKDIR=/data/mysql/backup
[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}
[ -d ${BACKDIR}/${DATE} ] || mkdir -p ${BACKDIR}/${DATE} 
[ ! -d ${BACKDIR}/${OLDDATE} ] || rm -rf ${BACKDIR}/${OLDDATE}


# Backup the database using mysqldump
mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD --default-character-set=utf8 --no-autocommit --quick --hex-blob --single-transaction $DB_NAME > $DB_NAME-$DATE.sql

# Compress the backup file
gzip -c $DB_NAME-$DATE.sql > ${BACKDIR}/${DATE}/$DB_NAME-$DATE.sql.gz

# Upload the compressed backup file to S3
aws s3 cp ${BACKDIR}/${DATE}/$DB_NAME-$DATE.sql.gz s3://$S3_BUCKET/$S3_PATH/