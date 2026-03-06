#!/bin/bash -e

sudo mkdir -p /var/www/html/opentakserver
sudo chmod a+rw /var/www/html/opentakserver
cd /var/www/html/opentakserver
lastversion --assets extract brian7704/OpenTAKServer-UI