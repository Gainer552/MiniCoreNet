#!/bin/bash

#MiniCoreNet - Main Launcher Script
#Location: ./MiniCoreNet/start.sh
CONFIG_FILE="config.json"
LOG_SCRIPT="./log_event.sh"

#Loads configs with jq.
load_config() {
    NODE_NAME=$(jq -r '.network.node_name' "$CONFIG_FILE")
    VAULT_PATH=$(jq -r '.vault.path' "$CONFIG_FILE")
    ENCRYPTED=$(jq -r '.vault.enabled' "$CONFIG_FILE")
    MOUNT_PATH=$(jq -r '.vault.mount_point' "$CONFIG_FILE")
}

log_event() {
    "$LOG_SCRIPT" "$1" "$2"
}

validate_environment() {
    echo "[*] Validating environment..."

    local required_files=("config.json" "log_event.sh" "connect.sh" "setup_auth.sh" "trust_manager.sh" "integrity_check.sh" "anonymize.sh" "file_share.sh")

    for f in "${required_files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "[ERROR] Missing required file: $f"
            exit 1
        fi
    done

    log_event "Environment validated for MiniCoreNet node: $NODE_NAME" "info"
}

mount_vault() {
    if [[ "$ENCRYPTED" == "true" ]]; then
        echo "[*] Mounting encrypted vault..."
        if [[ ! -d "$MOUNT_PATH" ]]; then
            mkdir -p "$MOUNT_PATH"
        fi
        sudo cryptsetup open "$VAULT_PATH" minicorevault || {
            echo "[ERROR] Failed to open encrypted vault."
            log_event "Encrypted vault mount failed." "error"
            return
        }
        sudo mount /dev/mapper/minicorevault "$MOUNT_PATH"
        log_event "Encrypted vault mounted to $MOUNT_PATH" "info"
    fi
}

menu() {
    while true; do
        clear
        cat << "EOF"
 _______ _______ __   _
 |  |  | |       | \  |
 |  |  | |_____  |  \_|
EOF
        echo ""
        echo "[1] Connect to a trusted node"
        echo "[2] Provision authentication"
        echo "[3] Trust manager"
        echo "[4] Run integrity check"
        echo "[5] File sharing (send/download)"
        echo "[6] Anonymize and route (MAC/IP/Tor/VPN)"
        echo "[7] Exit"
        echo ""

        read -rp "Select an option: " option

        case "$option" in
            1)
                ./connect.sh
                ;;
            2)
                ./setup_auth.sh
                ;;
            3)
                ./trust_manager.sh
                ;;
            4)
                ./integrity_check.sh
                ;;
            5)
                ./file_share.sh
                ;;
            6)
                ./anonymize.sh
                ;;
            7)
                echo "Goodbye."
                log_event "MiniCoreNet session exited." "info"
                exit 0
                ;;
            *)
                echo "[ERROR] Invalid option selected."
                sleep 2
                ;;
        esac
        read -rp "Press Enter to return to menu..." temp
    done
}

#Main execution flow.
load_config
validate_environment
mount_vault
menu
