#!/bin/bash -e

mkdir -p /home/tak/ots/ca

# Generate CA
cd /home/tak/.opentakserver_venv/lib/python3.*/site-packages/opentakserver
flask ots create-ca

sudo sed -i "s~SERVER_CERT_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.pem~g" /home/tak/ots/mediamtx/mediamtx.yml
sudo sed -i "s~SERVER_KEY_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.nopass.key~g" /home/tak/ots/mediamtx/mediamtx.yml
sudo sed -i "s~OTS_FOLDER~/home/tak/ots~g" /home/tak/ots/mediamtx/mediamtx.yml

sudo systemctl daemon-reload
sudo systemctl enable mediamtx
sudo systemctl start mediamtx