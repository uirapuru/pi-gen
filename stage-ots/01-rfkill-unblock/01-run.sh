#!/bin/bash -e

# Ensure rfkill is available and make Wi-Fi/radio unblocked by default

# Create systemd rfkill directory and mark known platform bluetooth devices as unblocked
mkdir -p "${ROOTFS_DIR}/var/lib/systemd/rfkill/"
for addr in 107d50c000.serial 3f215040.serial 20215040.serial fe215040.serial soc; do
	echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-${addr}:bluetooth"
done

# Ensure wireless is enabled for NetworkManager by default (if NM exists)
if [ -d "${ROOTFS_DIR}/var/lib/NetworkManager" ]; then
	cat > "${ROOTFS_DIR}/var/lib/NetworkManager/NetworkManager.state" <<- EOF
	[main]
	WirelessEnabled=true
	EOF
fi

# Create a small systemd oneshot service to unblock rfkill at boot
cat > "${ROOTFS_DIR}/etc/systemd/system/unblock-rfkill.service" << 'EOF'
[Unit]
Description=Unblock rfkill at boot
After=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/unblock-rfkill.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Script to execute at boot
cat > "${ROOTFS_DIR}/usr/local/bin/unblock-rfkill.sh" << 'EOF'
#!/bin/bash

# Unblock all radios if rfkill tool present
if command -v rfkill >/dev/null 2>&1; then
    rfkill unblock all || true
fi

# If nmcli present, ensure wifi radio is on
if command -v nmcli >/dev/null 2>&1; then
    nmcli radio wifi on || true
fi
EOF

chmod +x "${ROOTFS_DIR}/usr/local/bin/unblock-rfkill.sh"

# Ensure hostapd and wifi-ap services are started after unblock-rfkill
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/hostapd.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/hostapd.service.d/10-unblock.conf" << 'EOF'
[Unit]
After=unblock-rfkill.service
EOF

mkdir -p "${ROOTFS_DIR}/etc/systemd/system/wifi-ap.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/wifi-ap.service.d/10-unblock.conf" << 'EOF'
[Unit]
After=unblock-rfkill.service
EOF

# Enable the services (safe: ignore failures if unit missing)
on_chroot << CHROOT_EOF
systemctl enable unblock-rfkill.service || true
systemctl enable hostapd.service || true
systemctl enable wifi-ap.service || true
CHROOT_EOF

