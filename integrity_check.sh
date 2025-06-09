#!/bin/bash

#MiniCoreNet - Integrity Check Script
#Performs daily SHA-256 checksums on all log files to detect tampering.
CONFIG_FILE="config.json"
HASHES_DIR=$(jq -r '.integrity.hashes_dir' "$CONFIG_FILE")
LOG_DIR=$(jq -r '.integrity.target_dir' "$CONFIG_FILE")
ALERT_ON_FAIL=$(jq -r '.integrity.alert_on_fail' "$CONFIG_FILE")
LOG="./log_event.sh"

mkdir -p "$HASHES_DIR"

log_msg() {
    "$LOG" "$1" "$2"
}

verify_file() {
    local file="$1"
    local base_name
    local hash_file
    local current_hash
    local stored_hash

    base_name=$(basename "$file")
    hash_file="$HASHES_DIR/${base_name}.sha256"

    current_hash=$(sha256sum "$file" | awk '{print $1}')

    if [[ -f "$hash_file" ]]; then
        stored_hash=$(cat "$hash_file")
        if [[ "$current_hash" == "$stored_hash" ]]; then
            echo "[OK] $file"
        else
            echo "[FAIL] $file"
            log_msg "INTEGRITY FAILURE: $file hash mismatch" "alert"
            [[ "$ALERT_ON_FAIL" == "true" ]] && echo "WARNING: Integrity issue detected in $file"
        fi
    else
        echo "$current_hash" > "$hash_file"
        echo "[INIT] Recorded new hash for $file"
        log_msg "Hash initialized for $file" "info"
    fi
}

#Run integrity check on all *.log files in the log directory.
for logfile in "$LOG_DIR"/*.log; do
    [[ -f "$logfile" ]] && verify_file "$logfile"
done
