#!/bin/sh
# Desktop Commander entrypoint v1.4.0
# 1. Development dir を自動検出
# 2. 初回のみ config を事前書き込み
# 3. DC 起動後に set_config_value で確実に allowedDirectories を設定

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

# 初回のみ: DC 起動前に config を pre-populate
if [ ! -s "$CONFIG" ]; then
  mkdir -p "$(dirname "$CONFIG")"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$CONFIG', JSON.stringify({
      allowedDirectories: ['$ALLOWED_DIR'],
      blockedCommands: ['nc','ncat','netcat','scp','sftp','ftp','telnet',
        'mkfs','format','mount','umount','fdisk','dd','parted','diskpart',
        'sudo','su','passwd','adduser','useradd','usermod','groupadd','chsh',
        'visudo','shutdown','reboot','halt','poweroff','init',
        'iptables','firewall','netsh','sfc','bcdedit','reg','net','sc',
        'runas','cipher','takeown']
    }, null, 2));
    process.stderr.write('entrypoint: first-run config initialized for $ALLOWED_DIR\n');
  "
fi

# DC 起動後に allowedDirectories を確実に設定（毎回）
# DC の MCP ツール経由ではなく npx で直接設定
(
  sleep 3
  node -e "
    const fs = require('fs');
    const p = '$CONFIG';
    const d = '$ALLOWED_DIR';
    try {
      const raw = fs.readFileSync(p, 'utf8');
      const c = JSON.parse(raw);
      if (c.allowedDirectories[0] !== d) {
        c.allowedDirectories = [d];
        c.blockedCommands = ['nc','ncat','netcat','scp','sftp','ftp','telnet',
          'mkfs','format','mount','umount','fdisk','dd','parted','diskpart',
          'sudo','su','passwd','adduser','useradd','usermod','groupadd','chsh',
          'visudo','shutdown','reboot','halt','poweroff','init',
          'iptables','firewall','netsh','sfc','bcdedit','reg','net','sc',
          'runas','cipher','takeown'];
        fs.writeFileSync(p, JSON.stringify(c, null, 2));
        process.stderr.write('entrypoint: config corrected -> ' + d + '\n');
      } else {
        process.stderr.write('entrypoint: config OK -> ' + d + '\n');
      }
    } catch(e) {
      process.stderr.write('entrypoint: error - ' + e.message + '\n');
    }
  "
) &

exec desktop-commander
