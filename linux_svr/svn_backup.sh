
#!/bin/bash
# This script is used to backup a SVN repository
# The repository path is passed as an argument to the script
# The backup is saved in a folder named "svn_backup" in the user's home directory
# The backup file is named with the current date and time
# The backup file is compressed using gzip

# Check if repository path is provided as argument
if [ $# -eq 0 ]
then
  echo "Repository path not provided"
  exit 1
fi

# Get current date and time
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OLDDATE=$(date +%Y-%m-%d -d '30 days')
SVNDIR=/data/svn
BACKDIR=/data/backup/svn-backup
SVNADMIN=/usr/bin/svnadmin

# Create backup folder if it does not exist
mkdir -p ~/svn_backup

# Backup repository and compress using gzip
for PROJECT in myproject official analysis mypharma
do
    cd $SVNDIR
    $SVNADMIN hotcopy $PROJECT $BACKDIR/$DATE/$PROJECT --clean-logs
    cd $BACKDIR/$DATE
    tar -zcf ${PROJECT}_svn_${DATE}.tar.gz $PROJECT > /dev/null
    rm -rf $PROJECT
    echo "Backup of SVN repository $PROJECT completed successfully"
    sleep 2
done



# Print success message



# FTP login and file upload
# Replace the placeholders with your FTP server details, username, and password
# Change the remote directory to the desired location on the FTP server

# FTP server details
ftp_server="192.168.226.20"
ftp_username="admin"
ftp_password="admin"

# Remote directory on FTP server
# quote USER $ftp_username
# quote PASS $ftp_password
remote_dir="/data/svn"

cd ${BACKDIR}/${DATE}
# Upload backup file to FTP server
ftp -i -n -v  <<!
open ${ftp_server}
user ${ftp_username} ${ftp_password}
bin
cd ${OLDDATE}
mdelete *
cd ..
rmdir ${OLDDATE}
mkdir ${DATE}
mput *
bye
!

# Print success message
echo "Backup file uploaded to FTP server successfully"