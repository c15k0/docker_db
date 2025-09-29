#!/bin/sh
set -euo pipefail
set -x

DATE=$(date +%F_%H%M)
MYSQL_HOST="sql"
MYSQL_USER="root"
MYSQL_PASS="${MYSQL_ROOT_PASSWORD}"
S3="s3://${AWS_BACKUP_BUCKET}/${ENVIRONMENT}"
OUTDIR="/tmp/mysql-backup-${DATE}"

mkdir -p "$OUTDIR"

DBS=`mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASS" \
     -e "SHOW DATABASES;" \
     | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$"`
     
for DB in $DBS; do
  echo "Dumping $DB..."
  mysqldump --host="$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASS" \
    --single-transaction --routines --triggers --events \
    "$DB" \
    | gzip > "$OUTDIR/${DB}.sql.gz"
done

tar -czf "/tmp/mysql-backup-${DATE}.tar.gz" -C "$OUTDIR" .
echo "Backup generated in /tmp/mysql-backup-${DATE}.tar.gz"

aws s3 cp "/tmp/mysql-backup-${DATE}.tar.gz" "${S3}/mysql/"

rm -rf "$OUTDIR" "$OUTFILE"

if [[ "${SKIP_MONGO_DUMP:-0}" != "1" ]]; then

  mongodump --host nosql --username "${MONGO_USER}" --password "${MONGO_PASSWORD}" \
    --authenticationDatabase admin --gzip --archive="/tmp/mongo-${DATE}.archive.gz" 

  aws s3 cp "/tmp/mongo-${DATE}.archive.gz" "${S3}/mongo/"
  rm /tmp/mongo-${DATE}.archive.gz
fi

exit 1