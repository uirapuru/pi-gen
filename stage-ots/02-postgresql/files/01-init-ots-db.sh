#!/bin/bash

pg_ctlcluster 15 main start

OTS_DB_EXISTS=$(sudo -u postgres psql -XtAc "SELECT 1 FROM pg_database WHERE datname='ots'")
OTS_USER_EXISTS=$(sudo -u postgres psql -tXAc "SELECT 1 from pg_roles WHERE rolname='ots'")

if [ -z "$OTS_USER_EXISTS" ]; then
sudo -u postgres psql -c "create role ots with login password 'POSTGRESQL_PASSWORD';"
fi

if [ -z "$OTS_DB_EXISTS" ]; then
sudo -u postgres psql -c "create database ots;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"ots\" TO ots;"
sudo -u postgres psql -d ots -c "GRANT ALL ON SCHEMA public TO ots;"
fi

cd /home/tak/.opentakserver_venv/lib/python3.*/site-packages/opentakserver
flask db upgrade

pg_ctlcluster 15 main stop

rm -f /etc/rc.local.d/01-init-ots-db.sh