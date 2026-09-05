# Google Drive Backup Tools (`gdrive-backup`)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python: 3.8+](https://img.shields.io/badge/Python-3.8+-brightgreen.svg)](https://www.python.org/)
[![rclone: backend](https://img.shields.io/badge/Backend-rclone-orange.svg)](https://rclone.org/)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)]()

A robust, incremental Google Drive backup utility and real-time status monitor built on top of [rclone](https://rclone.org/) and systemd user services.

Current version: **1.1.0**

Provides background job execution, natural-language timer scheduling, pre-backup transfer size estimation, and real-time progress monitoring with live terminal dashboards.

---

## Key Features

- **`gdrive-backup-status`**:
  - Reports whether an incremental backup is currently active or idle.
  - Shows exact start timestamp, human-readable elapsed duration, and remaining ETA.
  - Visual ASCII/Unicode progress bars for both **bytes transferred** and **file counts**.
  - Displays real-time transfer speeds and checks completed.
  - Lists individual files currently transferring and recently copied items.
  - **Live Watch Mode (`-w` / `--watch`)**: Continuously refreshes the progress dashboard every 2–3 seconds in your terminal.
  - **JSON Output (`--json`)**: Structured output for integration into scripts and monitoring dashboards.

- **`gdrive-backup-now`**:
  - Immediately starts an incremental backup as a background systemd user service (`document-astrolab-backup.service` / `gdrive-backup.service`).
  - Supports foreground execution (`--fg`) with direct rclone progress.
  - Prevents accidental duplicate transfers if a backup is already running.

- **`gdrive-bakup-schedule`**:
  - Schedules backups at human-friendly times (e.g. `"23:30"`, `"tomorrow 02:00"`, `"+2 hours"`, or `"2026-09-05 23:30"`).
  - Uses transient systemd calendar timers (`systemd-run --on-calendar`).
  - Automatically checks for past times and provides clear format guidance.

- **`gdrive-backup-estimate`**:
  - Performs a fast dry-run scan against Google Drive to estimate how many new/modified files need copying.
  - Calculates estimated transfer time across standard internet bandwidths (500 KiB/s, 1 MiB/s, 2 MiB/s, 10 MiB/s).
  - Automatically routes to live transfer progress if a backup is already active.

- **`gdrive-backup-stop`**:
  - Gracefully stops active background backup services and cancels scheduled timers.

- **Safe & Non-Destructive**:
  - Uses incremental copy policy—remote files absent locally are **never deleted**.

---

## Installation

### Option 1: One-Line Installer (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/prasundutta151/gdrive-backup/main/install.sh | bash
```

### Option 2: Clone and Install

```bash
git clone https://github.com/prasundutta151/gdrive-backup.git
cd gdrive-backup
./install.sh
```

To enable aliases immediately in your current terminal session:
```bash
source ~/.bashrc   # or source ~/.bash_aliases
```

### Uninstallation

```bash
./uninstall.sh
```

---

## Prerequisites

1. **Python 3.8+** (standard library only, no third-party pip dependencies required).
2. **rclone**:
   ```bash
   # Ubuntu / Debian
   sudo apt install rclone

   # Or official script
   curl https://rclone.org/install.sh | sudo bash
   ```
3. **Configure the folders and Google Drive account**:
   ```bash
   gdrive-setup --local ~/Documents --web Document_Astrolab
   ```
   `gdrive-setup` reuses an existing `gdrive:` remote or opens rclone's Google
   authentication flow when it needs to create one.

---

## Usage & Examples

### 0. Configure folders and Google Drive

`gdrive-setup` performs the initial setup, saves the default local and Drive
folders, and creates or verifies rclone's Google Drive authentication:

```bash
gdrive-setup --local ~/Documents --web Document_Astrolab
```

`--web` accepts either a folder name (using the default `gdrive` remote) or a
complete rclone destination:

```bash
gdrive-setup --local ~/Research --web gdrive:Research_Backup
gdrive-setup --show
gdrive-setup --reauth
```

The defaults are saved in `~/.config/gdrive-backup/config.json`. Command-level
`--source` and `--dest` options still override them for a single run.

### 1. Check Backup Status

Check whether a backup is running, when it started, and its live completion progress:

```bash
gdrive-backup-status
```

Sample output:
```text
====================================================================
 Google Drive Backup — Status: ACTIVE / RUNNING  [2026-09-05 10:06:57]
====================================================================
 Status:           RUNNING / IN PROGRESS
 Service Unit:     document-astrolab-backup.service (active)
 Process PID:      129242
 Source Folder:    /home/user/Documents
 Destination:      gdrive:Document_Astrolab
 Policy:           Incremental (existing remote files preserved)

 [Timing Information]
   • Started At:   Sat 2026-09-05 08:15:56 IST (1h 51m ago)
   • Elapsed Time: 1h 51m 01s
   • Estimated ETA: 4w1d22h26m remaining

 [Transfer Progress]
   • Data Transferred: 2.676 GiB / 5.999 GiB (45%)
     [███████████░░░░░░░░░░░░░] 45.0%
   • Files Processed:  726 / 10738 files (7%)
     [██░░░░░░░░░░░░░░░░░░░░░░] 7.0%
   • Transfer Speed:   1.347 KiB/s
   • Already Synced:   9 / 9 files (100%)
   • Errors / Retries: 1 (retrying may help)

 [Currently Transferring Files]
   • Projects/sample_plots/plot-ant0.png (0% of 230.64 KiB)
   • Projects/sample_plots/plot-ant11.png (0% of 232.40 KiB)
   • Projects/sample_plots/plot-ant12.png (0% of 221.86 KiB)

 [Recently Copied Files]
   • Reports/arx/report_051.txt (new)
   • Reports/arx/report_052.txt (new)
====================================================================
 Commands:
   • Live Watch:   gdrive-backup-status --watch
   • Stop Backup:  gdrive-backup-stop
```

#### Real-Time Terminal Dashboard (`--watch` / `-w`)

```bash
gdrive-backup-status --watch
```

#### JSON Output (`--json`)

```bash
gdrive-backup-status --json
```

---

### 2. Start Incremental Backup Immediately

```bash
# Back up default source (~/Documents) in background:
gdrive-backup-now

# Back up a specific directory:
gdrive-backup-now --source ~/Research

# Run in foreground with interactive live progress:
gdrive-backup-now --fg
```

---

### 3. Schedule Incremental Backup

```bash
# Run at a specific time tonight (or tomorrow if passed):
gdrive-bakup-schedule "23:30"

# Run tomorrow at a specific time:
gdrive-bakup-schedule "tomorrow 02:00"

# Run relative to current time:
gdrive-bakup-schedule "+2 hours"

# Full timestamp with specific folder:
gdrive-bakup-schedule "2026-09-05 23:30:00" --source ~/Documents
```

If run without arguments, `gdrive-bakup-schedule` displays full syntax and format instructions.

---

### 4. Estimate Upload Size & Required Time

Scans differences between local directory and Google Drive without uploading anything:

```bash
gdrive-backup-estimate
gdrive-backup-estimate --source ~/Projects
```

Sample output:
```text
==================================================================
 Google Drive Backup — Pre-Backup Estimate
==================================================================
 Source:           /home/user/Documents
 Destination:      gdrive:Document_Astrolab
 Policy:           Incremental (no remote deletions)
 Local Summary:    10738 files (~5.99 GiB)
 Scanning differences against Google Drive (dry-run)...

 Scan Results:
   • Files to Backup:  124 new or modified file(s)
   • Data to Transfer: 320.50 MiB
   • Already Synced:   10614 file(s) up-to-date

 Estimated Transfer Time Needed:
   • At 500 KiB/s (typical upload)  : ~10m 41s
   • At 1 MiB/s (standard rate)     : ~5m 20s
   • At 2 MiB/s (fast upload)       : ~2m 40s
   • At 10 MiB/s (high-speed fiber) : ~32s
==================================================================
```

---

### 5. Stop Backup & Cancel Timers

```bash
# Stops any running rclone backup process and cancels pending timers:
gdrive-backup-stop

# Cancel only pending scheduled timers:
gdrive-backup-stop --timer-only
```

---

## Configuration & Environment Variables

You can customize default paths globally via environment variables:

| Variable | Default Value | Description |
|---|---|---|
| `GDRIVE_REMOTE` | `gdrive` | Remote name in rclone configuration |
| `GDRIVE_BACKUP_SOURCE` | `~/Documents` | Default local directory to back up |
| `GDRIVE_BACKUP_DEST` | `gdrive:Document_Astrolab` | Default destination on Google Drive |

Example in `~/.bashrc`:
```bash
export GDRIVE_BACKUP_DEST="gdrive:MyBackups/Laptop"
```

---

## License

This project is licensed under the [MIT License](LICENSE).
