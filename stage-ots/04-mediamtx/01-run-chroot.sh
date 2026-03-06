#!/bin/bash -e

mkdir -p /home/tak/ots/mediamtx/recordings
cd /home/tak/ots/mediamtx

lastversion --filter '~*linux_arm64' --assets download bluenviron/mediamtx -o /home/tak/ots/mediamtx --only 1.13.0

cd /home/tak/ots/mediamtx
tar -xf ./*.tar.gz

systemctl daemon-reload
systemctl enable mediamtx
systemctl start mediamtx