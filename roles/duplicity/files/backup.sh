#!/usr/bin/env bash

source  /home/duplicity/email-settings.sh

MAX_TIME="3M"
FULL_BACKUP_EVERY="1M"
SOURCE="/mnt/MAIN"
DESTINATION="onedrive://duplicity/nas"

LOG="/home/duplicity/backup.log"

rm $LOG
PASSPHRASE="$PASSPHRASE" duplicity remove-older-than $MAX_TIME $DESTINATION >> $LOG
PASSPHRASE="$PASSPHRASE" duplicity --full-if-older-than $FULL_BACKUP_EVERY $SOURCE $DESTINATION >> $LOG

sendemail \
  -f "$EMAIL_SENDER" \
  -t "$EMAIL_RECEIPIENT" \
  -u "Duplicity backup log" \
  -message-file=$LOG \
  -s "$EMAIL_SERVER" \
  -xu "$EMAIL_USER" \
  -xp "$EMAIL_PASSWORD" \
  -o "tls=$EMAIL_TLS"
