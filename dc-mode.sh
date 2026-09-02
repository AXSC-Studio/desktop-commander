#!/bin/bash
# dc-mode.sh — Desktop Commander の実行モードを切り替える
#
#   bash dc-mode.sh host     # DXT拡張（macOSホスト直起動）へ。macOSコマンドが打てる／全FS見える
#   bash dc-mode.sh docker   # Docker Shield（コンテナ）へ。Development+Downloadsのみ
#   bash dc-mode.sh status   # 今どっちか表示するだけ
#
# 「並存」は 2026-07-18〜09-01 の45日間ノーガードの原因なので、
# このスクリプトは常に片方だけを有効化する（排他）。
#
# 切り替え後は Claude Desktop の再起動（Cmd+Q → 起動）が必要。

set -uo pipefail

S="$HOME/Library/Application Support/Claude"
EXT_DIR="$S/Claude Extensions"
DC_EXT="ant.dir.gh.wonderwhy-er.desktopcommandermcp"
CFG="$S/claude_desktop_config.json"
INST="$S/extensions-installations.json"
STAMP="$(date +%Y%m%d_%H%M%S)"

c_ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
c_warn() { printf '\033[33m%s\033[0m\n' "$*"; }
c_err()  { printf '\033[31m%s\033[0m\n' "$*"; }

[ -d "$S" ] || { c_err "Claude の設定フォルダが見つかりません: $S"; exit 1; }

# ---------- 現在のモード判定 ----------
detect_mode() {
  local docker_entry="no" ext_enabled="no"
  if [ -f "$CFG" ] && grep -q '"desktop-commander"' "$CFG" 2>/dev/null; then
    docker_entry="yes"
  fi
  if [ -d "$EXT_DIR/$DC_EXT" ]; then
    ext_enabled="yes"
  fi
  echo "$docker_entry $ext_enabled"
}

show_status() {
  read -r d e <<<"$(detect_mode)"
  echo "──────────────────────────────────────────"
  echo " claude_desktop_config.json の docker エントリ : $d"
  echo " DXT拡張ディレクトリ                          : $e"
  echo "──────────────────────────────────────────"
  if [ "$d" = "yes" ] && [ "$e" = "yes" ]; then
    c_err " 現在: 並存（危険。45日ノーガードの再来）→ どちらかに寄せてください"
  elif [ "$d" = "yes" ]; then
    c_ok  " 現在: docker（Docker Shield / Development+Downloads のみ）"
  elif [ "$e" = "yes" ]; then
    c_ok  " 現在: host（DXT拡張 / macOSコマンド可・広い可視範囲）"
  else
    c_warn " 現在: どちらも無効（Desktop Commander が動きません）"
  fi
  echo
  echo " 退避済みDXT拡張:"
  ls -d "$EXT_DIR/$DC_EXT".disabled-* 2>/dev/null | sed 's|.*/|   |' || echo "   （なし）"
  echo " 設定バックアップ:"
  ls -1 "$S"/claude_desktop_config.json.*.bak 2>/dev/null | sed 's|.*/|   |' || echo "   （なし）"
}

# ---------- host モードへ ----------
to_host() {
  read -r d e <<<"$(detect_mode)"
  if [ "$e" = "yes" ] && [ "$d" = "no" ]; then
    c_ok "すでに host モードです。何もしません。"; exit 0
  fi

  # 1) 今の docker 構成を退避（あとで docker に戻せるように）
  if [ -f "$CFG" ]; then
    cp "$CFG" "$S/claude_desktop_config.json.shield.$STAMP.bak"
    c_ok "退避: claude_desktop_config.json.shield.$STAMP.bak"
  fi
  if [ -f "$INST" ]; then
    cp "$INST" "$S/extensions-installations.json.shield.$STAMP.bak"
  fi

  # 2) DXT拡張ディレクトリを復帰
  local disabled
  disabled="$(ls -d "$EXT_DIR/$DC_EXT".disabled-* 2>/dev/null | head -1)"
  if [ -d "$EXT_DIR/$DC_EXT" ]; then
    c_ok "DXT拡張: すでに有効"
  elif [ -n "$disabled" ]; then
    mv "$disabled" "$EXT_DIR/$DC_EXT"
    c_ok "DXT拡張を復帰: $(basename "$disabled") -> $DC_EXT"
  else
    c_err "退避済みのDXT拡張が見つかりません。"
    c_err "Claude Desktop の Settings > Extensions から Desktop Commander を入れ直してください。"
    exit 1
  fi

  # 3) pre-shield バックアップから設定を復元
  local pre_cfg pre_inst
  pre_cfg="$(ls -1t "$S"/claude_desktop_config.json.pre-shield.*.bak 2>/dev/null | head -1)"
  pre_inst="$(ls -1t "$S"/extensions-installations.json.pre-shield.*.bak 2>/dev/null | head -1)"

  if [ -n "$pre_cfg" ]; then
    cp "$pre_cfg" "$CFG"
    c_ok "復元: $(basename "$pre_cfg") -> claude_desktop_config.json"
  else
    # バックアップが無い場合は docker エントリだけを外す
    if command -v python3 >/dev/null 2>&1 && [ -f "$CFG" ]; then
      python3 - "$CFG" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p))
srv=d.get("mcpServers",{})
if "desktop-commander" in srv:
    del srv["desktop-commander"]
    d["mcpServers"]=srv
    json.dump(d,open(p,"w"),indent=2,ensure_ascii=False)
    print("removed desktop-commander entry")
else:
    print("no desktop-commander entry")
PY
      c_warn "pre-shield バックアップが無いため、docker エントリのみ除去しました"
    fi
  fi
  [ -n "$pre_inst" ] && cp "$pre_inst" "$INST" && c_ok "復元: $(basename "$pre_inst")"

  echo
  c_ok "=== host モードへ切り替え完了 ==="
  c_warn "Claude Desktop を Cmd+Q で完全終了して、起動し直してください。"
  echo
  c_warn "注意: ホスト直起動の DC は allowedDirectories が空だと全FS無制限になります。"
  c_warn "再起動後に Claude へ「DCのallowedDirectoriesを設定して」と言えば設定できます。"
}

# ---------- docker モードへ ----------
to_docker() {
  read -r d e <<<"$(detect_mode)"

  local shield_cfg
  shield_cfg="$(ls -1t "$S"/claude_desktop_config.json.shield.*.bak 2>/dev/null | head -1)"
  if [ -z "$shield_cfg" ]; then
    c_err "Shield構成のバックアップが見つかりません。"
    c_err "~/Development/desktop_commander/README.md の STEP 4 を手動で適用してください。"
    exit 1
  fi

  cp "$CFG" "$S/claude_desktop_config.json.host.$STAMP.bak" 2>/dev/null
  cp "$shield_cfg" "$CFG"
  c_ok "復元: $(basename "$shield_cfg") -> claude_desktop_config.json"

  # 並存させない: DXT拡張を退避
  if [ -d "$EXT_DIR/$DC_EXT" ]; then
    mv "$EXT_DIR/$DC_EXT" "$EXT_DIR/$DC_EXT.disabled-$STAMP"
    c_ok "DXT拡張を退避（並存防止）: $DC_EXT.disabled-$STAMP"
  fi

  if ! docker info >/dev/null 2>&1; then
    c_warn "Docker Desktop が起動していません。起動しないと DC は接続できません。"
  fi

  echo
  c_ok "=== docker モードへ切り替え完了 ==="
  c_warn "Claude Desktop を Cmd+Q で完全終了して、起動し直してください。"
}

case "${1:-status}" in
  host)   to_host ;;
  docker) to_docker ;;
  status) show_status ;;
  *) echo "usage: bash dc-mode.sh [host|docker|status]"; exit 1 ;;
esac
