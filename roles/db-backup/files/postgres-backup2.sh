#!/usr/bin/env bash

set -x

HOST=192.168.50.100
PORT=5433
USER=postgres
PASS=
DEST=/srv/backup/db/postgres

DATABASES=$(PGPASSWORD="$PASS" psql -h $HOST -p $PORT -U $USER -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d')
DIR="${DEST}/$(date +"%F")"
mkdir -p "$DIR"

for db in $DATABASES; do
  FILE="${DIR}/$db.sql.gz"
  echo "backing up $db to $FILE"

  [ "$db" != "postgres" ] && [ "$db" != "template0" ] && [ "$db" != "template1" ] || continue
  # Be sure to make one backup per day
  [ -f $FILE ] && continue

  PGPASSWORD="$PASS" pg_dump --username=$USER --host=$HOST --port=$PORT "$db" | gzip > "$FILE"
done
