#!/bin/bash
#
# Duplicity backup script for Linux workstations. 
#
# This backup policy will do an incremental backup every single day. Every
# month, run a new full backup. Keep two full months of daily history but
# only keep the last 3 full backups (3 months).

ROOT_DIR="/opt/backup-duplicity"
DUPLICITY="/usr/bin/duplicity"
PIDFILE="/var/run/backup-duplicity.pid"

# Variables: Backup Policy
BACKUP_SOURCE="/"
EXCLUDE="--exclude /dev \
    --exclude /proc \
    --exclude /sys \
    --exclude /tmp \
    --exclude /run \
    --exclude /mnt \
    --exclude /media \
    --exclude /lost+found \
    --exclude /**.cache"
PASSPHRASE='xxxxxxxxxxxxxxxxxxxxxxxxxxx'	# use single quotes to keep special chars ($)
FULL_FREQ="1M"					# create a new full backup every...
FULL_LIFE="2M"					# delete any full backup older than...
INCR_KEEP=2					# how many full+incr cycle to keep

# Variables: Backup Target
DEST="rsync://user@backup.target/relative/path"
SSH_KEY="$ROOT_DIR/keys/id_duplicity"


######################
# Script Begins Here #
######################

echo "Starting backup job"

# Set env variables
export PASSPHRASE=$PASSPHRASE

# Prevent from running multiple instances with a lock file
if [ -f $PIDFILE ]
then
	echo "Backup job is already running (PID "$(cat $PIDFILE)")"
	exit 1
else
	echo $$ > $PIDFILE
fi

# Run backup
echo "Run duplicity backup (dynamically choose inc. or full)"
$DUPLICITY --full-if-older-than $FULL_FREQ $EXCLUDE --rsync-options="-e 'ssh -i $SSH_KEY'" "$BACKUP_SOURCE" $DEST

# do not continue if duplicity backup failed (SHOULD IMPROVE BY MOVING unsetenv AND rm into a UNLOAD_ENV function)
if [ $? -ne 0 ] 
then
	echo "Duplicity backup terminated before completion, exiting..."
	rm -f $PIDFILE
	exit 1
fi

# Remove all backup older than FULL_LIFE
echo "Run duplicity to remove all backup older than $FULL_LIFE"
$DUPLICITY remove-older-than $FULL_LIFE --force --rsync-options="-e 'ssh -i $SSH_KEY'" $DEST

# Remove all incremental backup older than 
echo "Run duplicity to only keep last $INCR_KEEP full cycle (incr+full)"
$DUPLICITY remove-all-inc-of-but-n-full $INCR_KEEP --force --rsync-options="-e 'ssh -i $SSH_KEY'" $DEST

# Display collection status
echo "Run duplicity to display collection status"
$DUPLICITY collection-status --rsync-options="-e 'ssh -i $SSH_KEY'" $DEST

# Delete lock file before leaving
rm -f $PIDFILE

echo "Backup job completed"
