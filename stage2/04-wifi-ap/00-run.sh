#!/bin/bash -e

# Configure WiFi Access Point with hostapd and dnsmasq

# Create hostapd configuration directory
mkdir -p "${ROOTFS_DIR}/etc/hostapd"

# Create hostapd configuration file
cat > "${ROOTFS_DIR}/etc/hostapd/hostapd.conf" << 'EOF'
interface=wlan0
driver=nl80211
ssid=atak
hw_mode=g
channel=6
wmm_enabled=1
macaddr_acl=0
auth_algs=1
wpa=2
wpa_passphrase=atakatak
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey=86400
ieee80211n=1
EOF

# Create dnsmasq configuration for AP
cat > "${ROOTFS_DIR}/etc/dnsmasq.d/03-rpi-hostapd.conf" << 'EOF'
# WiFi AP configuration
interface=wlan0
dhcp-range=10.42.0.100,10.42.0.255,255.255.255.0,24h
dhcp-option=option:router,10.42.0.1
dhcp-leasefile=/var/lib/misc/dnsmasq.leases
EOF

# Create systemd service to enable AP on startup
cat > "${ROOTFS_DIR}/etc/systemd/system/wifi-ap.service" << 'EOF'
[Unit]
Description=WiFi Access Point Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/start-wifi-ap.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create startup script for WiFi AP
cat > "${ROOTFS_DIR}/usr/local/bin/start-wifi-ap.sh" << 'EOF'
#!/bin/bash

# Wait for wlan0 to be ready
sleep 2

# Unblock radio devices if rfkill is available
if command -v rfkill >/dev/null 2>&1; then
    rfkill unblock all || true
fi

# If NetworkManager is present, ensure wireless is enabled
if command -v nmcli >/dev/null 2>&1; then
    nmcli radio wifi on || true
fi

# Configure wlan0 interface
ip link set wlan0 up
ip addr add 10.42.0.1/24 dev wlan0

# Start hostapd
hostapd /etc/hostapd/hostapd.conf &

# Start dnsmasq
systemctl start dnsmasq

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF

chmod +x "${ROOTFS_DIR}/usr/local/bin/start-wifi-ap.sh"

# Enable the service
on_chroot << CHROOT_EOF
systemctl enable wifi-ap.service
CHROOT_EOF
