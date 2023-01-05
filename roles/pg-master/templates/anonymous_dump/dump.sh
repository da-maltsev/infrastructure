#!/bin/sh -e

SRC="postgres://{{ app_postgresql_user }}:{{ app_postgresql_password }}@{{ postgresql_host }}:{{ postgresql_port }}/{{
app_postgresql_database }}?sslmode=require"
DST=/home/circle/anon_production_dump.sql.gz

dump=$(mktemp /tmp/anon-pg-dump.XXXXXX)

echo Dumping data...
docker run --network host --rm -v /root/anonymous_dump/config:/app -w /app datanymizer/pg_datanymizer:0.6.0 -c config.yml --accept_invalid_certs $SRC -- --no-owner --no-privileges>$dump

filesize=$(stat --format="%s" $dump)

if [ $filesize -le 100000 ]; then
  echo "Dump failed, filesize < 100k"
  rm -f $dump
  exit 127
fi;

echo Raw dump size is $(numfmt --to=si $filesize)
echo Compressing...

gzip -c $dump > $DST

filesize=$(stat --format="%s" $DST)
if [ $filesize -le 10000 ]; then
  echo "Dump compression failed, filesize < 10k"
  rm -f $dump
  exit 127
fi;

chown circle $DST
rm -f $dump

echo Compressed dump saved to to $DST
echo Final size is $(numfmt --to=si $filesize)

echo Pinging safe-backup.ru...
curl https://sb-ping.ru/EEEgTQ6PzsTrVyVb6bH6yi
