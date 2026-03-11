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