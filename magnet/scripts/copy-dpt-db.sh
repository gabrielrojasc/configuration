#!/usr/bin/env sh

set -euo pipefail

host=${1:-$(basename $(pwd))}
server=${2:-dev}
service=${3:-postgres}

psql \
	-c "drop database if exists \"${PGDATABASE}\";" \
	-c "create database \"${PGDATABASE}\";" \
	postgres

ssh $host.$server \
	"cd $host && docker-compose exec -T $service pg_dump --format=custom" |
	pg_restore --dbname="${PGDATABASE}" --no-owner --no-acl

./manage.py migrate
./manage.py createsuperuser --no-input
