#!/bin/sh
# Desktop Commander entrypoint
# DC_ALLOWED_DIR が未設定の場合、/Users/*/Development を自動検出する

if [ -n "$DC_ALLOWED_DIR" ]; then
  ALLOWED_DIR="$DC_ALLOWED_DIR"
else
  DETECTED=$(find /Users -maxdepth 2 -name "Development" -type d 2>/dev/null | head -1)
  ALLOWED_DIR="${DETECTED:-/workspace}"
fi

CONFIG="/root/.claude-server-commander/config.json"

mkdir -p /opt/homebrew/bin
ln -sf /usr/bin/gh /opt/homebrew/bin/gh 2>/dev/null || true

patch_config() {
  node -e "
    const fs = require('fs');
    const p = '$CONFIG';
    const d = '$ALLOWED_DIR';
    try {
      const c = JSON.parse(fs.readFileSync(p, 'utf8'));
      c.allowedDirectories = [d];
      c.blockedCommands = [
        'mkfs','format','mount','umount','fdisk','dd','parted','diskpart',
        'sudo','su','passwd','adduser','useradd','usermod','groupadd','chsh',
        'visudo','shutdown','reboot','halt','poweroff','init',
        'iptables','firewall','netsh','sfc','bcdedit','reg','net','sc',
        'runas','cipher','takeown',
        'nc','ncat','netcat','scp','sftp','ftp','telnet'
      ];
      fs.writeFileSync(p, JSON.stringify(c, null, 2));
    } catch(e) {
      process.stderr.write('entrypoint: patch failed: ' + e.message + '\n');
    }
  "
}

( sleep 1 && patch_config ) &
exec desktop-commander
