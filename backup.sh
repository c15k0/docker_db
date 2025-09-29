#!/bin/sh
set -euo pipefail

DATE=$(date +%F_%H%M)
S3="s3://${AWS_BACKUP_BUCKET}/${ENVIRONMENT}"

mysqldump --host=sql -uroot -p"${MYSQL_ROOT_PASSWORD}" --plugin-dir=/usr/lib/mariadb/plugin \
  --all-databases --single-transaction --routines --triggers --events \
  | gzip > "/tmp/mysql-${DATE}.sql.gz"

aws s3 cp "/tmp/mysql-${DATE}.sql.gz" "${S3}/mysql/"

mongodump --host nosql --username "${MONGO_USER}" --password "${MONGO_PASSWORD}" \
  --authenticationDatabase admin --gzip --archive="/tmp/mongo-${DATE}.archive.gz" 

aws s3 cp "/tmp/mongo-${DATE}.archive.gz" "${S3}/mongo/"

rm -f /tmp/mysql-${DATE}.sql.gz /tmp/mongo-${DATE}.archive.gz