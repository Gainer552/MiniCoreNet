#!/bin/bash

#MiniCoreNet - Trust Manager
#Manages trusted public keys and key rotation.
CONFIG_FILE="config.json"
TRUSTED_KEYS_DIR=$(jq -r '.auth.trusted_keys_dir' "$CONFIG_FILE")
LOCAL_PRIV_KEY=$(jq -r '.auth.local_private_key' "$CONFIG_FILE")
LOCAL_PUB_KEY=$(jq -r '.auth.local_public_key' "$CONFIG_FILE")
LOG="./log_event.sh"

#Ensures the required directories exist.
mkdir -p "$TRUSTED_KEYS_DIR"

log_msg() {
    "$LOG" "$1" "$2"
}

add_peer() {
    echo "Paste the peer's public key:"
    read -r PEER_KEY

    FINGERPRINT=$(echo "$PEER_KEY" | sha256sum | awk '{print $1}')
    KEY_FILE="$TRUSTED_KEYS_DIR/$FINGERPRINT.pub"

    echo "$PEER_KEY" > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    log_msg "Added new trusted key: $FINGERPRINT" "info"
    echo "Trusted peer added. Fingerprint: $FINGERPRINT"
}

remove_peer() {
    echo "Enter the fingerprint of the peer to remove:"
    read -r FINGERPRINT
    KEY_FILE="$TRUSTED_KEYS_DIR/$FINGERPRINT.pub"

    if [[ -f "$KEY_FILE" ]]; then
        rm "$KEY_FILE"
        log_msg "Removed trusted key: $FINGERPRINT" "info"
        echo "Trusted peer removed."
    else
        echo "Fingerprint not found."
        log_msg "Failed to remove key: $FINGERPRINT not found" "warn"
    fi
}

rotate_keys() {
    echo "Rotating key pair..."

    #Backs up old keys.
    TIMESTAMP=$(date +%s)
    mv "$LOCAL_PRIV_KEY" "${LOCAL_PRIV_KEY}.bak_$TIMESTAMP"
    mv "$LOCAL_PUB_KEY" "${LOCAL_PUB_KEY}.bak_$TIMESTAMP"

    #Generate new key pair.
    ssh-keygen -t rsa -b 4096 -N "" -f "$LOCAL_PRIV_KEY" >/dev/null

    log_msg "Key pair rotated. Backup saved with timestamp $TIMESTAMP" "info"
    echo "Key rotation complete. Previous keys backed up."
}

list_trusted() {
    echo "Trusted peers:"
    for keyfile in "$TRUSTED_KEYS_DIR"/*.pub; do
        [[ -f "$keyfile" ]] || continue
        FINGERPRINT=$(basename "$keyfile" .pub)
        echo "- $FINGERPRINT"
    done
}

usage() {
    echo "Usage: $0 {add|remove|rotate|list}"
    exit 1
}

#Entry point.
case "$1" in
    add)
        add_peer
        ;;
    remove)
        remove_peer
        ;;
    rotate)
        rotate_keys
        ;;
    list)
        list_trusted
        ;;
    *)
        usage
        ;;
esac
