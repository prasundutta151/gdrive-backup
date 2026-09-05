#!/usr/bin/env bash
# =============================================================================
# Google Drive Backup Tools - Uninstaller
# =============================================================================
set -e

TARGET_BIN_DIR="${HOME}/.local/bin"

COMMANDS=(
    "gdrive-backup"
    "gdrive-backup-status"
    "gdrive-status"
    "gdrive-backup-now"
    "gdrive-bakup-schedule"
    "gdrive-backup-schedule"
    "gdrive-backup-estimate"
    "gdrive-backup-stop"
)

echo "Removing installed Google Drive Backup tools from ${TARGET_BIN_DIR}..."
for cmd in "${COMMANDS[@]}"; do
    if [ -f "${TARGET_BIN_DIR}/${cmd}" ] || [ -L "${TARGET_BIN_DIR}/${cmd}" ]; then
        rm -f "${TARGET_BIN_DIR}/${cmd}"
        echo "  - Removed ${cmd}"
    fi
done

echo "Uninstallation complete."
