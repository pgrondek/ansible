#!/usr/bin/env bash

set -x

HOST=192.168.50.100
USER=root
PASS=
DEST=/srv/backup/db/mysql

DATABASES=$(mysql -h $HOST -u $USER -p$PASS -s -N -e "SHOW DATABASES;")
DIR="${DEST}/$(date +"%F")"
mkdir -p "$DIR"

for db in $DATABASES; do
  FILE="${DIR}/$db.sql.gz"
  echo "backing up $db to $FILE"

  [ "$db" != "information_schema" ] && [ "$db" != "mysql" ] && [ "$db" != "performance_schema" ] && [ "$db" != "sys" ] || continue
  # Be sure to make one backup per day
  [ -f $FILE ] && continue

  mysqldump --single-transaction --routines --quick -h $HOST -u $USER -p$PASS -B "$db" | gzip > "$FILE"
done
