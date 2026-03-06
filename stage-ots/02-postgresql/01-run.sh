#!/bin/bash -e

sudo systemctl start postgresql
systemctl status postgresql
sudo systemctl enable postgresql

OTS_DB_EXISTS=$(sudo su postgres -c "psql -XtAc \"SELECT 1 FROM pg_database WHERE datname='ots'\"")
OTS_USER_EXISTS=$(sudo su postgres -c "psql -tXAc \"SELECT 1 from pg_roles WHERE rolname='ots'\"")

POSTGRESQL_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 20)
sudo su postgres -c "psql -c \"create role ots with login password '${POSTGRESQL_PASSWORD}';\""
sed -i "s/POSTGRESQL_PASSWORD/${POSTGRESQL_PASSWORD}/g" /home/tak/ots/config.yml
sudo su postgres -c "psql -c 'create database ots;'"
sudo su postgres -c "psql -c 'GRANT ALL PRIVILEGES  ON DATABASE \"ots\" TO ots;'"
sudo su postgres -c "psql -d ots -c 'GRANT ALL ON SCHEMA public TO ots;'"

cd /home/tak/.opentakserver_venv/lib/python3.*/site-packages/opentakserver
flask db upgrade

