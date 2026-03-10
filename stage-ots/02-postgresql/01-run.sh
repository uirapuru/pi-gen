POSTGRESQL_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 20)

sed -i "s/POSTGRESQL_PASSWORD/${POSTGRESQL_PASSWORD}/g" ${ROOTFS_DIR}/home/tak/ots/config.yml

install -m 755 files/01-init-ots-db.sh ${ROOTFS_DIR}/etc/rc.local.d/01-init-ots-db.sh

sed -i "s/POSTGRESQL_PASSWORD/${POSTGRESQL_PASSWORD}/g" ${ROOTFS_DIR}/etc/rc.local.d/01-init-ots-db.sh