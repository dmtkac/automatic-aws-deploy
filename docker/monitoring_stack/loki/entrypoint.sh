#!/bin/sh
set -e

chown -R 1000:999 /loki # Adjust UID:GID according to environment, using 'id' command

for dir in /loki/cache /loki/index /loki/compactor; do
  [ ! -d "$dir" ] && mkdir -p "$dir"
  chown -R 1000:999 "$dir"
done

exec /usr/bin/loki -config.file=/etc/loki/config.yml