#!/bin/bash -e

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv B6391CB2CFBA643D
echo "deb http://zeroc.com/download/Ice/3.7/ubuntu`lsb_release -rs` stable main" | tee /etc/apt/sources.list.d/zeroc.list
apt update

NEEDRESTART_MODE=a apt install mumble-server zeroc-ice-all-runtime zeroc-ice-all-dev -y

sed -i '/ice="tcp -h 127.0.0.1 -p 6502"/s/^#//g' /etc/mumble-server.ini
sed -i 's/icesecretwrite/;icesecretwrite/g' /etc/mumble-server.ini
service mumble-server restart

PASSWORD_LOG=$(grep -m 1 SuperUser /var/log/mumble-server/mumble-server.log)
PASSWORD=($PASSWORD_LOG)