#!/bin/bash

#MiniCoreNet - Secure Connection Script
#Requirements: wireguard-tools, jq, openssl
#Config File: config.json
CONFIG_FILE="config.json"
LOG="./log_event.sh"
TMP_PEER_AUTH="/tmp/mcn_peer_auth.tmp"

#Function to log messages.
log_msg() {
    "$LOG" "$1" "$2"
}

#Checks for required files.
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_msg "Config file not found: $CONFIG_FILE" "error"
    exit 1
fi

if [[ ! -f "$LOG" ]]; then
    echo "Logging script not found: $LOG"
    exit 1
fi

#Loads config values.
VPN_INTERFACE=$(jq -r '.vpn.interface' "$CONFIG_FILE")
VPN_CONFIG=$(jq -r '.vpn.config_path' "$CONFIG_FILE")
PEER_ENDPOINT=$(jq -r '.vpn.peer_endpoint' "$CONFIG_FILE")
LOCAL_PRIV_KEY=$(jq -r '.auth.local_private_key' "$CONFIG_FILE")
TRUSTED_KEYS_DIR=$(jq -r '.auth.trusted_keys_dir' "$CONFIG_FILE")

#Sanity checks.
if [[ ! -f "$VPN_CONFIG" ]]; then
    log_msg "VPN config missing: $VPN_CONFIG" "error"
    exit 1
fi

if [[ ! -f "$LOCAL_PRIV_KEY" ]]; then
    log_msg "Private key missing: $LOCAL_PRIV_KEY" "error"
    exit 1
fi

if [[ ! -d "$TRUSTED_KEYS_DIR" ]]; then
    log_msg "Trusted keys directory missing: $TRUSTED_KEYS_DIR" "error"
    exit 1
fi

#Step 1: Connects to VPN.
wg-quick up "$VPN_INTERFACE" &>/dev/null
if [[ $? -ne 0 ]]; then
    log_msg "Failed to establish VPN connection on interface $VPN_INTERFACE" "error"
    exit 1
fi
log_msg "VPN connection established on $VPN_INTERFACE" "info"

#Step 2: Authenticates peer (public key handshake).
PEER_PUB_KEY=$(ssh "$PEER_ENDPOINT" "cat ~/.minicorenet/id_rsa.pub" 2>/dev/null)
if [[ -z "$PEER_PUB_KEY" ]]; then
    log_msg "Failed to retrieve peer public key from $PEER_ENDPOINT" "error"
    wg-quick down "$VPN_INTERFACE" &>/dev/null
    exit 1
fi

#Saves peer key for auditing.
echo "$PEER_PUB_KEY" > "$TMP_PEER_AUTH"

#Checks for trust.
FINGERPRINT=$(echo "$PEER_PUB_KEY" | sha256sum | awk '{print $1}')
if grep -q "$FINGERPRINT" "$TRUSTED_KEYS_DIR"/* 2>/dev/null; then
    log_msg "Peer authenticated: fingerprint $FINGERPRINT" "info"
else
    log_msg "UNTRUSTED peer attempted connection: fingerprint $FINGERPRINT" "warn"
    wg-quick down "$VPN_INTERFACE" &>/dev/null
    exit 1
fi

#Confirmation of authentication.
log_msg "Secure connection authenticated and live." "info"

exit 0
