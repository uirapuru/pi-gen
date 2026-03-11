#!/bin/bash -e

apt-get purge -y apt-listchanges || true

mkdir -p /home/tak/ots

python3 -m venv --system-site-packages /home/tak/.opentakserver_venv
source /home/tak/.opentakserver_venv/bin/activate
pip3 install opentakserver

cd /home/tak/.opentakserver_venv/lib/python3.*/site-packages/opentakserver
# This command won't overwrite config.yml if it exists
flask ots generate-config

