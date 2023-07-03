#!/usr/bin/env sh

set -euo pipefail

host=${1:-$(basename $(pwd))}
server=${2:-dev}
service=${3:-postgres}

readonly LOCAL_DUMPS_PATH=./db_dumps
local_dump_path="$LOCAL_DUMPS_PATH/__tmp__.dump"

psql \
	-c "drop database if exists \"${PGDATABASE}\";" \
	-c "create database \"${PGDATABASE}\";" \
	postgres

ssh $host.$server "cd $host && docker-compose exec -T $service pg_dump --format=custom" >$local_dump_path
pg_restore --dbname="${PGDATABASE}" --no-owner --no-acl --jobs="$(sysctl -n hw.logicalcpu)" "$local_dump_path"
rm $local_dump_path

./manage.py migrate
./manage.py createsuperuser --no-input
