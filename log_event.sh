#!/bin/bash

#MiniCoreNet - Logging Utility
#Usage: ./log_event.sh "Your log message" [level]
CONFIG_FILE="config.json"
LOG_LEVEL="${2:-info}"

#Function: Extract value from JSON config.
get_config_value() {
  jq -r "$1" "$CONFIG_FILE" 2>/dev/null
}

#Checks if the config file exists.
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [error] Config file $CONFIG_FILE not found." >&2
  exit 1
fi

#Loads log directory and log level.
LOG_DIR=$(get_config_value '.logging.log_dir')
RETENTION_DAYS=$(get_config_value '.logging.log_retention_days')
CONFIG_LOG_LEVEL=$(get_config_value '.logging.log_level')

#Fallback to defaults if config values are missing.
LOG_DIR=${LOG_DIR:-"./logs"}
RETENTION_DAYS=${RETENTION_DAYS:-30}
CONFIG_LOG_LEVEL=${CONFIG_LOG_LEVEL:-info}

#Creates a log directory if missing.
mkdir -p "$LOG_DIR"

#Defines log file path (rotated daily).
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d').log"

#Append log.
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LOG_LEVEL] $1"
} >> "$LOG_FILE"

#Optional: Clean old logs.
find "$LOG_DIR" -type f -name "*.log" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null

exit 0
