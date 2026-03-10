#!/bin/bash -e

install -m 755 files/mediamtx.service "${ROOTFS_DIR}/etc/systemd/system/mediamtx.service"
install -m 755 files/mediamtx.yml "${ROOTFS_DIR}/home/tak/ots/mediamtx/mediamtx.yml"

pipx install lastversion

export PATH=$PATH:/root/.local/bin

on_chroot << EOF

mkdir -p /home/tak/ots/mediamtx/recordings
cd /home/tak/ots/mediamtx

lastversion --filter '~*linux_arm64' --assets download bluenviron/mediamtx -o /home/tak/ots/mediamtx --only 1.13.0

cd /home/tak/ots/mediamtx
tar -xf ./*.tar.gz

systemctl enable mediamtx

EOF


