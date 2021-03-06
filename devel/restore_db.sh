#!/bin/bash
# FROMBACKUP: if set, it will use /var/www/html/$1.dump as a restore source
# TEMPRENAME: restore to $1_temp and then drop $1 and rename $1_temp to $1 (a lot less $1 downtime but more disk usage)
if [ -z "$1" ]
then
  echo "$0: you need to provide database name"
  echo "When running manually please copy/link /var/www/html/dbname.dump to current directory and remove after restore"
  exit 1
fi

if [ ! -z "$FROMBACKUP" ]
then
  ln /var/www/html/$1.dump $1.dump || exit 1
fi

if [ -z "$TEMPRENAME" ]
then
  ./devel/drop_psql_db.sh $1
  echo "Creating $1"
  ./devel/db.sh createdb $1 || exit 2
  ./devel/db.sh pg_restore -d $1 $1.dump || exit 3
  echo "Created $1"
else
  tdb="$1_temp"
  ./devel/drop_psql_db.sh $tdb
  echo "Creating $tdb"
  ./devel/db.sh createdb $tdb || exit 4
  ./devel/db.sh pg_restore -d $tdb $1.dump || exit 5
  echo "Created $tdb"
  ./devel/drop_psql_db.sh $1
  echo "Renaming $tdb to $1"
  ./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$tdb'" || exit 6
  ./devel/db.sh psql postgres -c "alter database \"$tdb\" rename to \"$1\"" || exit 7
  echo "Renamed $tdb to $1"
fi

if [ ! -z "$FROMBACKUP" ]
then
  rm $1.dump || exit 8
fi
