#!/bin/sh
# Desktop Commander entrypoint v1.7.1
# 1. DC_ALLOWED_DIR（":" 区切りで複数ディレクトリ指定可）を解決
# 2. DC 起動前に config を強制適用
# 3. DC 起動後にもう一度適用（DC 自身の初期化による上書きを打ち消す）
#
# v1.7.0 変更点: allowedDirectories の複数指定に対応（v1.6.0 までは単一のみ）

if [ -n "$DC_ALLOWED_DIR" ]; then
  ALLOWED_DIRS="$DC_ALLOWED_DIR"
else
  DETECTED=$(find /Users /home -maxdepth 2 -name "Development" -type d 2>/dev/null | head -1)
  ALLOWED_DIRS="${DETECTED:-/workspace}"
fi

CONFIG="/root/.claude-server-commander/config.json"

# macOS Homebrew 互換（ホスト側スクリプトが /opt/homebrew/bin/gh を前提にするため）
mkdir -p /opt/homebrew/bin
ln -sf /usr/bin/gh /opt/homebrew/bin/gh 2>/dev/null || true

export CFG="$CONFIG"
export DIRS="$ALLOWED_DIRS"

apply_config() {
  node -e '
    const fs = require("fs");
    const path = require("path");
    const p = process.env.CFG;
    const dirs = process.env.DIRS.split(":").filter(Boolean);
    const blocked = ["mkfs","format","mount","umount","fdisk","dd","parted","diskpart",
      "sudo","su","passwd","adduser","useradd","usermod","groupadd","chsh","visudo",
      "shutdown","reboot","halt","poweroff","init","iptables","firewall","netsh","sfc",
      "bcdedit","reg","net","sc","runas","cipher","takeown",
      "nc","ncat","netcat","scp","sftp","ftp","telnet"];
    let c = {};
    try { c = JSON.parse(fs.readFileSync(p, "utf8")); } catch (e) { c = {}; }
    const cur = Array.isArray(c.allowedDirectories) ? c.allowedDirectories : [];
    const dirsOk = cur.length === dirs.length && dirs.every((d, i) => cur[i] === d);
    const curBlocked = Array.isArray(c.blockedCommands) ? c.blockedCommands : [];
    const blockedOk = blocked.every(b => curBlocked.includes(b));
    if (dirsOk && blockedOk) {
      process.stderr.write("entrypoint: config OK -> " + dirs.join(", ") + "\n");
    } else {
      c.allowedDirectories = dirs;
      c.blockedCommands = blocked;
      fs.mkdirSync(path.dirname(p), { recursive: true });
      fs.writeFileSync(p, JSON.stringify(c, null, 2));
      process.stderr.write("entrypoint: config ENFORCED -> " + dirs.join(", ") + "\n");
    }
  '
}

# 起動前に適用
apply_config

# DC 起動後にも適用（DC が起動時に config を書き戻すケースへの保険）
( sleep 3; apply_config ) &

exec desktop-commander
