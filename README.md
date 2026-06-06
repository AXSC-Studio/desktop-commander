# 🛡️ Desktop Commander Docker Shield

[![GitHub stars](https://img.shields.io/github/stars/AXSC-Studio/desktop-commander?style=flat-square)](https://github.com/AXSC-Studio/desktop-commander/stargazers)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square)]()
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

> **DC** = Desktop Commander（このドキュメント全体での略称）

**Claude に Mac の全ファイルへのアクセスを与えていませんか？**

Desktop Commander はデフォルトで AI にホーム全体（`~/.ssh`、`~/.aws`、全 `.env`）への
アクセスを許可します。悪意あるプロンプトが1つ混入するだけで、**ユーザーの操作なしに**
SSH 秘密鍵が外部送信されます。これは理論ではなく、今日すぐ成立する攻撃です。

このリポジトリは **Docker Shield** を用いて Desktop Commander を安全に運用するための
完全な設定ファイルとマニュアルです。

---

## TL;DR

| | デフォルト DC | Docker Shield（このリポジトリ） |
|---|---|---|
| `~/.ssh` SSH 秘密鍵 | 🔴 盗める | ✅ 物理的に不可能 |
| `~/.aws` クラウド認証 | 🔴 盗める | ✅ 物理的に不可能 |
| 他プロジェクトの `.env` | 🔴 盗める | ✅ 物理的に不可能 |
| `git push` / `gh pr create` | ⚙️ ホスト依存 | ✅ DC 内で完全動作 |
| 開発サーバー起動 | ⚙️ ホスト依存 | ✅ ポートマップで対応 |
| セッション毎の手動設定 | 🔴 毎回必要 | ✅ 自動適用（不要） |


---

## なぜ Docker が必要か：Parasitic Toolchain Attack

```
① 侵入（EIT）   Webページ等の悪意ある命令が fetch 時に AI に混入
      ↓
② 収集（PAT）   汚染された AI が ~/.ssh / ~/.env を自律的に読み取る
      ↓
③ 漏洩（NAT）   curl 等で外部送信。ユーザー操作ゼロで完結
```

**根本原因：** LLM はデータと命令を区別できない（パッチ不能な原理的弱点）。
だから「たどり着けない構造」を Docker で作る。

---

## アーキテクチャ：制御は対象の「外側」に置く

```
┌─────────────────────────────────────────────────────────┐
│  macOS ホスト                                            │
│                                                          │
│   Claude Desktop ──stdio──▶                             │
│                             ┌───────────────────────┐   │
│   🔒 ~/.ssh    (マウントなし) │  Docker コンテナ       │  │
│   🔒 ~/.aws    (マウントなし) │                       │   │
│                             │  Desktop Commander    │   │
│   📂 ~/Development  ──────▶ │  + git + gh CLI       │   │
│   📄 ~/.config/gh  :ro ───▶ │                       │   │
│   📄 ~/.gitconfig  :ro ───▶ │  Port 映射            │   │
│                             │  blockedCommands      │   │
│                             └───────────────────────┘   │
│                                                          │
│  攻撃成功しても ~/.ssh には物理的に届かない               │
└─────────────────────────────────────────────────────────┘
```


---

## クイックスタート（概要）

```bash
# 1. クローン
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander && mkdir -p dc-data

# 2. gh 認証（ファイル保存で Docker から利用可能にする）
gh auth login -h github.com --insecure-storage

# 3. config.json を編集 → Docker イメージをビルド
bash build.sh desktop-commander:latest

# 4. Claude Desktop を再起動 → 完了
```

詳細は以下のステップバイステップを参照してください。

---

## 事前準備

- **gh CLI** がホスト Mac にインストール済みであること
  ```bash
  brew install gh
  ```
- **Docker Desktop** をインストール（STEP 1 参照）

---

## ファイル構成

```
desktop_commander/
├── Dockerfile        # コンテナ定義（git, gh CLI, bash, curl 含む）
├── entrypoint.sh     # 起動スクリプト（設定自動適用 + git 認証解決）
├── build.sh          # イメージビルドスクリプト
├── dc-config.json    # blockedCommands 参照用テンプレート
└── dc-data/          # DC ランタイムデータ（.gitignore 済み）
```


---

## STEP 0  リポジトリをクローンする

```bash
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander
mkdir -p dc-data
```

> `~/.gitconfig` が未設定の場合は先に設定してください：
> ```bash
> git config --global user.name 'あなたの名前'
> git config --global user.email 'your@email.com'
> ```

---

## STEP 1  Docker Desktop をインストールする

1. `https://www.docker.com/products/docker-desktop/` からダウンロード・インストール
2. 起動 → 「Use recommended settings」→「Finish」→「Skip」
3. 画面下部に「Engine running」が表示されれば完了
4. **「バックグラウンドでの実行を許可」→ 必ず許可**

**自動起動設定（推奨）：** 歯車アイコン > General >「Start Docker Desktop when you sign in」→ Apply

> ⚠️ Claude Desktop より先に Docker Desktop が起動している必要があります。

---

## STEP 2  DXT をアンインストールする

1. Claude Desktop → 設定 > 拡張機能 > desktop-commander →「アンインストール」
2. **Cmd+Q で完全終了**（ウィンドウを閉じるだけでは不可）

---

## STEP 3  GitHub CLI の認証を設定する

DC コンテナ内から `git push` / `gh pr create` を使うために、
`--insecure-storage` でトークンをファイルに保存します。

```bash
gh auth login -h github.com --insecure-storage
```

- Protocol: **HTTPS** を選択
- Authentication: **Login with a web browser** を選択
- 表示された `XXXX-XXXX` コードをブラウザで入力
- `Authentication credentials saved in plain text` が出れば成功

> **なぜ `--insecure-storage` が必要か**
> macOS 標準では gh トークンが Keychain に保存されます。
> Docker コンテナは Keychain にアクセスできないため、
> `~/.config/gh/hosts.yml` へのファイル保存が必要です。
> コンテナは `:ro`（読み取り専用）でマウントするため書き換えは不能です。


---

## STEP 4  claude_desktop_config.json を編集する

```bash
open -e "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
```

`mcpServers` に以下を追加（他のサーバーがある場合はカンマ区切りで追記）：

```json
"desktop-commander": {
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "-v", "/Users/あなたのユーザー名/Development:/Users/あなたのユーザー名/Development",
    "-v", "/Users/あなたのユーザー名/Development/desktop_commander/dc-data:/root/.claude-server-commander",
    "-v", "/Users/あなたのユーザー名/.config/gh:/root/.config/gh:ro",
    "-v", "/Users/あなたのユーザー名/.gitconfig:/root/.gitconfig:ro",
    "-e", "DC_ALLOWED_DIR=/Users/あなたのユーザー名/Development",
    "-p", "XXXX:XXXX",
    "-p", "YYYY:YYYY",
    "-p", "ZZZZ:ZZZZ",
    "--network", "bridge",
    "desktop-commander:latest"
  ]
}
```

**ユーザー名確認：** `whoami`

**ポート番号：** 開発サーバーで使うポートを指定。競合を避けるため 6000〜9999 を推奨。

```bash
# 空きポートの確認例
for port in 7432 7891 8743; do
  lsof -i :$port > /dev/null 2>&1 && echo "$port: 使用中" || echo "$port: 空き"
done
```

> **マウント設計の意図**
>
> | マウント | 権限 | 理由 |
> |---|---|---|
> | `/Development` | 読み書き | 作業ディレクトリ |
> | `~/.config/gh` | `:ro` | gh 認証トークン（改ざん防止） |
> | `~/.gitconfig` | `:ro` | git identity（改ざん防止） |
> | `~/.ssh` | **なし** | SSH 秘密鍵を物理的に保護 |

---

## STEP 5  Docker イメージをビルドする

```bash
cd ~/Development/desktop_commander
bash build.sh desktop-commander:latest
```

`Build complete: desktop-commander:latest` が表示されれば成功。

> Dockerfile を変更した場合は必ずリビルドすること。


---

## STEP 6  Claude Desktop を起動して確認する

1. Docker Desktop が起動していることを確認
2. Claude Desktop を起動 → 新しいチャットを開く
3. 以下を送信：

```
Desktop Commander の get_config を実行してください
```

| 確認項目 | 期待する値 |
|---|---|
| `isContainer` | `true` |
| `isDXT` | `false` |
| `allowedDirectories` | `["/Users/あなたのユーザー名/Development"]` |
| `blockedCommands` | `nc`、`ncat`、`scp` 等が含まれる |

---

## Docker Shield で使えるようになること

### DC 内で完全動作（ターミナル不要）

```bash
# git 操作（HTTPS 経由）
git add . && git commit -m "message" && git push

# GitHub CLI
gh pr create
gh auth status

# 開発サーバー（ホストブラウザから localhost:XXXX でアクセス可）
npm run dev -- --port XXXX
```

> **SSH git（`git@github.com:...`）は使えません。**
> `https://github.com/...` 形式を使ってください。
> HTTPS + gh auth が現代の標準です。

---

## セキュリティ設計：3層防御

```
Layer 1: Docker 壁        ← 主防御（常に有効・迂回不能）
  └─ ~/.ssh, ~/.aws → マウントなし = 物理的にアクセス不能

Layer 2: allowedDirectories ← ソフトウェア的な柵
  └─ /Development 外へのアクセスを DC が拒否

Layer 3: blockedCommands    ← 出口フィルタ
  └─ nc, scp, ftp 等の送信系コマンドをブロック
```

**⚠️ 残存ギャップ：** `curl` はヘルスチェックのため開放しています。
`/Development` 内の `.env` は理論上 curl で外部送信可能です。
Production 環境では `--network none` を検討してください。

---

## entrypoint.sh の自動処理

コンテナ起動ごとに以下が **自動適用** されます。毎回の手動設定は不要です。

1. `allowedDirectories` を `DC_ALLOWED_DIR` のパスに設定
2. `blockedCommands` に nc / scp / ftp 等を設定
3. macOS Homebrew の gh パスをコンテナ内 gh にリンク（git credential 解決）


---

## トラブルシューティング

| 症状 | 確認事項 |
|---|---|
| DC が反応しない | Docker Desktop が起動しているか確認 |
| `isContainer: false` | DXT が再インストールされていないか確認 |
| `allowedDirectories: []` | config.json に `DC_ALLOWED_DIR` が設定されているか確認 |
| `git push` が失敗 | `gh auth status` を確認 → 失敗なら STEP 3 を再実行 |
| build.sh でエラー | Docker Desktop の Engine が Running か確認 |

---

## チェックリスト

**初回セットアップ**
- [ ] リポジトリをクローン・`dc-data` ディレクトリを作成
- [ ] Docker Desktop インストール・起動済み・自動起動 ON
- [ ] DXT アンインストール済み（Cmd+Q で完全終了）
- [ ] `gh auth login -h github.com --insecure-storage` 完了
- [ ] `claude_desktop_config.json` 編集済み（4 マウント + ポート + DC_ALLOWED_DIR）
- [ ] `bash build.sh desktop-commander:latest` 成功
- [ ] `isContainer: true` + `allowedDirectories` が正しいパスで確認済み

**日常運用**
- [ ] Claude Desktop を開く前に Docker Desktop が起動していることを確認
- [ ] gh トークン期限切れ時は `gh auth login -h github.com --insecure-storage` を再実行

---

## コントリビュート

Issue・PR 歓迎します。特に以下を募集しています：

- Linux / Windows 対応
- `--network none` モードでの開発サーバー運用事例
- 他の MCP サーバーへの Docker Shield 適用事例

---

## 作者

**Peaske** — Indie Hacker / AI-Driven Accelerator

- 🐦 X（Twitter）: [@peaske_en](https://x.com/peaske_en)
- 🏢 Organization: [AXSC Studio](https://github.com/AXSC-Studio)

⭐ **このリポジトリが役に立ったらスターをお願いします！**
MCP セキュリティの認知向上に繋がります。

---

*MIT License — AXSC Studio*
