#!/bin/bash

echo "[*] Initializing Anonymity Stack..."

#Detects default network interface.
IFACE=$(ip route | grep default | awk '{print $5}')
if [[ -z "$IFACE" ]]; then
    echo "[!] No default network interface found."
    exit 1
fi

#Randomizes MAC.
echo "[*] Randomizing MAC address on interface: $IFACE"
sudo ip link set "$IFACE" down
sudo macchanger -r "$IFACE"
sudo ip link set "$IFACE" up
echo "[✓] MAC address randomized."

#Routing options menu.
echo
echo "Choose routing method:"
echo "[1] Route through Tor"
echo "[2] Use static WireGuard VPN"
echo "[3] Cancel"
read -rp "Select option: " route

case "$route" in
    1)
        echo "[*] Starting Tor service..."
        sudo systemctl start tor
        export https_proxy="socks5h://127.0.0.1:9050"
        export http_proxy="socks5h://127.0.0.1:9050"
        echo "[✓] Traffic routed through Tor."
        ;;
    2)
        echo "[*] Activating WireGuard VPN..."
        sudo wg-quick up /etc/wireguard/wg0.conf
        echo "[✓] VPN connection active via wg0."
        ;;
    3)
        echo "[*] Operation canceled."
        ;;
    *)
        echo "[!] Invalid option."
        ;;
esac

#Attempt to schedule hourly MAC rotation.
echo "[*] Scheduling automatic hourly MAC address changes..."

#Defines crontab line.
CRON_CMD="sudo ip link set $IFACE down && sudo macchanger -r $IFACE && sudo ip link set $IFACE up"
CRON_JOB="0 * * * * $CRON_CMD"

#Use root's crontab to ensure permission.
( sudo crontab -l 2>/dev/null; echo "$CRON_JOB" ) | sudo crontab -
echo "[✓] Hourly MAC address randomization scheduled in root's crontab."

echo
read -rp "Press Enter to return to main menu..."