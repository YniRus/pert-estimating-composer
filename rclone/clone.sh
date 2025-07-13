#!/bin/bash

RCLONE_REMOTE_NAME="gdrive"

DATE=$(date +"%d.%m.%Y")

echo "Starting backup process for $DATE at $(date)"

echo "Backing up server-storage..."
rclone copy ~/pert-estimating-composer/server-storage "${RCLONE_REMOTE_NAME}:rclone/pert-estimating/$DATE/server-storage"

echo "Backing up server-assets..."
rclone copy ~/pert-estimating-composer/server-assets "${RCLONE_REMOTE_NAME}:rclone/pert-estimating/$DATE/server-assets"

echo "Backup $DATE completed at $(date)"
