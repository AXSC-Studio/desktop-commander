#!/bin/sh
# Desktop Commander entrypoint
# Auto-detects Development dir. Pre-populates config on first run (before DC reads it).

if [ -n "$DC_ALLOWED_DIR" ]; then
  ALLOWED_DIR="$DC_ALLOWED_DIR"
else
  DETECTED=$(find /Users /home -maxdepth 2 -name "Development" -type d 2>/dev/null | head -1)
  ALLOWED_DIR="${DETECTED:-/workspace}"
fi

CONFIG="/root/.claude-server-commander/config.json"

# macOS Homebrew compatibility
mkdir -p /opt/homebrew/bin
ln -sf /usr/bin/gh /opt/homebrew/bin/gh 2>/dev/null || true

# First-run only: write correct config BEFORE DC starts (DC reads it on startup)
if [ ! -s "$CONFIG" ]; then
  mkdir -p "$(dirname "$CONFIG")"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$CONFIG', JSON.stringify({
      allowedDirectories: ['$ALLOWED_DIR'],
      blockedCommands: [
        'nc','ncat','netcat','scp','sftp','ftp','telnet',
        'mkfs','format','mount','umount','fdisk','dd','parted','diskpart',
        'sudo','su','passwd','adduser','useradd','usermod','groupadd','chsh',
        'visudo','shutdown','reboot','halt','poweroff','init',
        'iptables','firewall','netsh','sfc','bcdedit','reg','net','sc',
        'runas','cipher','takeown'
      ]
    }, null, 2));
    process.stderr.write('entrypoint: initialized config for $ALLOWED_DIR\n');
  "
fi

exec desktop-commander
