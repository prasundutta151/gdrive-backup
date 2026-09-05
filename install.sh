#!/usr/bin/env bash
# =============================================================================
# Google Drive Backup Tools - Installer
# https://github.com/prasundutta151/gdrive-backup
# =============================================================================
set -e

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_RED="\033[1;31m"

echo -e "${COLOR_BLUE}====================================================================${COLOR_RESET}"
echo -e "${COLOR_BLUE} Google Drive Backup Tools — Automated Installer${COLOR_RESET}"
echo -e "${COLOR_BLUE}====================================================================${COLOR_RESET}"

# 1. Check Python version
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: python3 is required but not found.${COLOR_RESET}"
    exit 1
fi

PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_OK=$(python3 -c 'import sys; print(1 if sys.version_info >= (3, 8) else 0)')
if [ "$PY_OK" -ne 1 ]; then
    echo -e "${COLOR_RED}Error: Python 3.8 or newer is required (found Python $PY_VER).${COLOR_RESET}"
    exit 1
fi
echo -e " ${COLOR_GREEN}✓${COLOR_RESET} Found Python $PY_VER"

# 2. Check rclone
if ! command -v rclone >/dev/null 2>&1; then
    echo -e " ${COLOR_YELLOW}! Warning: rclone is not currently installed.${COLOR_RESET}"
    echo -e "   Please install rclone to connect with Google Drive:"
    echo -e "   Ubuntu/Debian: sudo apt install rclone"
    echo -e "   curl:          curl https://rclone.org/install.sh | sudo bash"
else
    RCLONE_V=$(rclone version | head -n 1)
    echo -e " ${COLOR_GREEN}✓${COLOR_RESET} Found $RCLONE_V"
fi

# 3. Determine install destination
TARGET_BIN_DIR="${HOME}/.local/bin"
mkdir -p "$TARGET_BIN_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BIN="${SCRIPT_DIR}/bin/gdrive-backup"

# Support direct piped curl execution: curl ... | bash
if [ ! -f "$SOURCE_BIN" ]; then
    echo -e " Downloading latest gdrive-backup from GitHub..."
    TMP_DOWNLOAD=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/prasundutta151/gdrive-backup/main/bin/gdrive-backup" -o "$TMP_DOWNLOAD"
    SOURCE_BIN="$TMP_DOWNLOAD"
fi

cp -f "$SOURCE_BIN" "${TARGET_BIN_DIR}/gdrive-backup"
chmod +x "${TARGET_BIN_DIR}/gdrive-backup"

if [ -n "$TMP_DOWNLOAD" ] && [ -f "$TMP_DOWNLOAD" ]; then
    rm -f "$TMP_DOWNLOAD"
fi

# 4. Create symlinks for all tool commands
COMMANDS=(
    "gdrive-setup"
    "gdrive-backup-status"
    "gdrive-status"
    "gdrive-backup-now"
    "gdrive-bakup-schedule"
    "gdrive-backup-schedule"
    "gdrive-backup-estimate"
    "gdrive-backup-stop"
)

for cmd in "${COMMANDS[@]}"; do
    ln -sf "${TARGET_BIN_DIR}/gdrive-backup" "${TARGET_BIN_DIR}/${cmd}"
done
echo -e " ${COLOR_GREEN}✓${COLOR_RESET} Installed binaries and symlinks into ${TARGET_BIN_DIR}"

# 5. Ensure PATH includes ~/.local/bin
PATH_CONFIGURED=0
if [[ ":$PATH:" == *":${TARGET_BIN_DIR}:"* ]]; then
    PATH_CONFIGURED=1
fi

SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi
if [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ "$PATH_CONFIGURED" -eq 0 ] && [ -n "$SHELL_RC" ]; then
    if ! grep -q 'export PATH=.*\.local/bin' "$SHELL_RC" 2>/dev/null; then
        echo -e '\n# Added by gdrive-backup installer\nexport PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo -e " ${COLOR_GREEN}✓${COLOR_RESET} Added ~/.local/bin to PATH in $SHELL_RC"
    fi
fi

# 6. Optional aliases in ~/.bash_aliases or ~/.bashrc
ALIASES_FILE=""
if [ -f "$HOME/.bash_aliases" ]; then
    ALIASES_FILE="$HOME/.bash_aliases"
elif [ -f "$HOME/.bashrc" ]; then
    ALIASES_FILE="$HOME/.bashrc"
fi

if [ -n "$ALIASES_FILE" ]; then
    if ! grep -q "alias gdrive-backup-status=" "$ALIASES_FILE" 2>/dev/null; then
        cat << 'ALIASES_BLOCK' >> "$ALIASES_FILE"

# =============================================================================
# Google Drive Backup Utilities
# =============================================================================
alias gdrive-backup-status='gdrive-backup-status'
alias gdrive-backup-now='gdrive-backup-now'
alias gdrive-bakup-schedule='gdrive-bakup-schedule'
alias gdrive-backup-schedule='gdrive-backup-schedule'
alias gdrive-backup-estimate='gdrive-backup-estimate'
alias gdrive-backup-stop='gdrive-backup-stop'
ALIASES_BLOCK
        echo -e " ${COLOR_GREEN}✓${COLOR_RESET} Added utility aliases to $ALIASES_FILE"
    fi
fi

echo -e "\n${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN} Installation Complete!${COLOR_RESET}"
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo -e "Available commands:"
echo -e "  • ${COLOR_BLUE}gdrive-setup${COLOR_RESET}              - Configure folders and Google Drive authentication"
echo -e "  • ${COLOR_BLUE}gdrive-backup-status${COLOR_RESET}     - Check active backup status, elapsed time & progress"
echo -e "  • ${COLOR_BLUE}gdrive-backup-status -w${COLOR_RESET}  - Live updating terminal progress display"
echo -e "  • ${COLOR_BLUE}gdrive-backup-now${COLOR_RESET}        - Start incremental backup immediately"
echo -e "  • ${COLOR_BLUE}gdrive-bakup-schedule${COLOR_RESET}    - Schedule backup at specific date/time"
echo -e "  • ${COLOR_BLUE}gdrive-backup-estimate${COLOR_RESET}   - Estimate files and upload duration"
echo -e "  • ${COLOR_BLUE}gdrive-backup-stop${COLOR_RESET}       - Stop active backup and cancel timers"
echo -e "\nTo activate aliases immediately in this terminal, run:"
echo -e "  source ~/.bashrc  (or source ~/.bash_aliases)\n"
