#!/bin/bash

HOME_DIR=$(eval echo ~)

if [ -f "${HOME_DIR}/pert-estimating-composer/.env" ]; then
    source "${HOME_DIR}/pert-estimating-composer/.env"
else
    echo "Error: File .env is not found"
    exit 1
fi

if [ -z "$RCLONE_REMOTE_NAME" ]; then
  echo "Error: RCLONE_REMOTE_NAME environment variable is not set"
  exit 1
fi

DATE=$(date +"%d.%m.%Y")

echo "Starting backup process for $DATE at $(date)"

echo "Backing up server-storage..."
rclone copy "${HOME_DIR}/pert-estimating-composer/server-storage" "${RCLONE_REMOTE_NAME}:rclone/pert-estimating/$DATE/server-storage"

echo "Backing up server-assets..."
rclone copy "${HOME_DIR}/pert-estimating-composer/server-assets" "${RCLONE_REMOTE_NAME}:rclone/pert-estimating/$DATE/server-assets"

echo "Backup $DATE completed at $(date)"
