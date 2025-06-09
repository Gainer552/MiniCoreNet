#!/bin/bash

#MiniCoreNet - setup_auth.sh
#One-time identity provisioning and trust store initialization

#Initialization
KEY_NAME="identity_key"
KEY_DIR="./keys"
TRUSTED_KEYS_DIR="./trusted_keys"
LOG_SCRIPT="./log_event.sh"

#Functions

#Log event helper.
log_event() {
    if [[ -x "$LOG_SCRIPT" ]]; then
        "$LOG_SCRIPT" "AUTH_SETUP" "$1"
    else
        echo "[!] Logging script not found or not executable."
    fi
}

#Starts script.

echo "[*] Starting authentication setup..."

#Create directories if non existant.
mkdir -p "$KEY_DIR"
mkdir -p "$TRUSTED_KEYS_DIR"

#Check if a key already exists.
if [[ -f "$KEY_DIR/$KEY_NAME" ]]; then
    echo "[!] Key already exists at $KEY_DIR/$KEY_NAME"
    log_event "Key generation skipped - already exists."
    exit 1
fi

#Generates ed25519 key pair.
echo "[*] Generating new ed25519 key pair..."
ssh-keygen -t ed25519 -f "$KEY_DIR/$KEY_NAME" -N "" -C "MiniCoreNetLocalKey"

if [[ $? -ne 0 ]]; then
    echo "[!] Failed to generate key pair."
    log_event "Key generation failed."
    exit 1
fi

#Adds a public key to trusted store with a user-defined label.
read -p "Enter a label for your node (e.g., Node01): " NODE_LABEL
cp "$KEY_DIR/$KEY_NAME.pub" "$TRUSTED_KEYS_DIR/$NODE_LABEL.pub"

#Restricts key permissions.
chmod 600 "$KEY_DIR/$KEY_NAME"
chmod 644 "$KEY_DIR/$KEY_NAME.pub"
chmod 644 "$TRUSTED_KEYS_DIR/$NODE_LABEL.pub"

#Confirmation of setup.
echo "[+] Keypair created and $NODE_LABEL added to trust store."
log_event "Keypair created and trusted key saved as $NODE_LABEL."

exit 0