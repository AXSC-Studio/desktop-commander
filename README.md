# 🛡️ Desktop Commander Docker Shield

[![GitHub stars](https://img.shields.io/github/stars/AXSC-Studio/desktop-commander?style=flat-square)](https://github.com/AXSC-Studio/desktop-commander/stargazers)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square)]()
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

**🌐 [English](#-english) · [中文](#-中文) · [日本語](#-日本語)**

---

## 🇬🇧 English

### What is MCP?

MCP (Model Context Protocol) is the world's fastest-growing AI infrastructure standard — adopted by 28% of Fortune 500 companies, powering 20,000+ servers with 97M+ monthly SDK downloads, and named the #1 IT Infrastructure Technology of 2026. Every major AI company (Anthropic, OpenAI, Google, Amazon, Microsoft) has rallied behind it. It is the "USB-C of AI" — a universal connector that gives AI true hands and feet to operate autonomously.

**Desktop Commander is Anthropic's flagship MCP tool.** With it, Claude can read/write files, execute terminal commands, manage git repositories, and run dev servers — all autonomously.

### ⚠️ But there is a critical security risk.

By default, Desktop Commander gives Claude access to your **entire home directory** — including `~/.ssh` (SSH private keys) and `~/.aws` (cloud credentials). A single malicious prompt injected into any webpage Claude reads can silently exfiltrate your secrets. No user action required. This is the **Parasitic Toolchain Attack**.

```
① Inject  — Malicious instruction hidden in a webpage Claude fetches
② Collect — Compromised AI autonomously reads ~/.ssh, .env files
③ Exfil   — Data sent to attacker via curl. Zero user interaction.
```

### The Solution: Docker Shield

This repository implements **Docker Shield** — a container isolation layer that makes your secrets **physically unreachable** while keeping git, GitHub CLI, and dev servers fully functional inside DC.

| | Default DC | Docker Shield |
|---|---|---|
| `~/.ssh` SSH keys | 🔴 Stealable | ✅ Physically impossible |
| `~/.aws` cloud creds | 🔴 Stealable | ✅ Physically impossible |
| `git push` / `gh pr` | ⚙️ Host only | ✅ Works inside DC |
| Dev server | ⚙️ Host only | ✅ Port-mapped |
| Manual session setup | 🔴 Every time | ✅ Auto-applied |

### Quick Start

```bash
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander && mkdir -p dc-data
gh auth login -h github.com --insecure-storage
bash build.sh desktop-commander:latest
```

See the [Japanese section](#-日本語) for the complete step-by-step guide.

### Author

**Peaske** — Indie Hacker / AI-Driven Accelerator
🐦 [@peaske_en](https://x.com/peaske_en) · 🏢 [AXSC Studio](https://github.com/AXSC-Studio)

⭐ **Star this repo** if it helped protect your secrets!


---

## 🇨🇳 中文

### 什么是 MCP？

MCP（模型上下文协议）是全球增长最快的 AI 基础设施标准。财富 500 强中 28% 的企业已采用，服务器数量超过 2 万个，每月 SDK 下载量达 9700 万次，并荣获 2026 年度 IT 基础设施技术大奖第一名。Anthropic、OpenAI、Google、Amazon、Microsoft 等各大 AI 巨头均已采用同一标准——这在科技史上极为罕见。MCP 被称为"AI 界的 USB-C"，是让 AI 真正拥有"手脚"、能够自主操作计算机的通用连接标准。

**Desktop Commander 是 Anthropic 官方旗舰 MCP 工具。** 通过它，Claude 可以自主读写文件、执行终端命令、管理 Git 仓库、启动开发服务器——无需人工干预。

### ⚠️ 但存在严重的安全风险

默认情况下，Desktop Commander 允许 AI 访问您的**整个主目录**，包括 `~/.ssh`（SSH 私钥）和 `~/.aws`（云端凭证）。只要 Claude 读取了含有恶意提示词的网页，攻击就会自动完成——您的密钥将被静默泄露，无需任何用户操作。这就是**寄生工具链攻击（Parasitic Toolchain Attack）**。

```
① 注入 — 恶意指令隐藏在 Claude 抓取的网页中
② 收集 — 被感染的 AI 自主读取 ~/.ssh、.env 等文件
③ 泄露 — 通过 curl 将数据发送给攻击者，全程零用户交互
```

### 解决方案：Docker Shield

本仓库实现了 **Docker Shield** —— 一种容器隔离层，使您的密钥**在物理层面无法访问**，同时保持 git、GitHub CLI 和开发服务器在 DC 内部完全可用。

| | 默认 DC | Docker Shield |
|---|---|---|
| `~/.ssh` SSH 私钥 | 🔴 可被窃取 | ✅ 物理隔离，无法访问 |
| `~/.aws` 云端凭证 | 🔴 可被窃取 | ✅ 物理隔离，无法访问 |
| `git push` / `gh pr` | ⚙️ 依赖宿主机 | ✅ DC 内部完整运行 |
| 开发服务器 | ⚙️ 依赖宿主机 | ✅ 端口映射支持 |
| 每次会话手动配置 | 🔴 每次都需要 | ✅ 自动应用，无需操作 |

### 快速开始

```bash
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander && mkdir -p dc-data
gh auth login -h github.com --insecure-storage
bash build.sh desktop-commander:latest
```

完整的分步骤指南请参阅[日本語部分](#-日本語)（含完整配置说明）。

### 作者

**Peaske** — 独立开发者 / AI 驱动创业加速者
🐦 [@peaske_en](https://x.com/peaske_en) · 🏢 [AXSC Studio](https://github.com/AXSC-Studio)

⭐ **如果本项目对您有帮助，请给个 Star！**


---

## 🇯🇵 日本語

> **DC** = Desktop Commander（このドキュメント全体での略称）

### MCP とは？── AI に「手足」が生える世界共通規格

MCP（Model Context Protocol）は今、世界で最も注目される IT インフラ標準です。財富 Fortune 500 の 28% が導入済み、サーバー数 2 万超、月間 SDK ダウンロード 9700 万回、ITインフラテクノロジーAWARD 2026 グランプリ受賞。Anthropic・OpenAI・Google・Amazon・Microsoft が競合関係にもかかわらず同一規格に合意するという前例のない事態が起きています。

MCP は「AI 界の USB-C」── AI とあらゆるツールの間に共通の差し込み口を作る規格です。これにより AI は「答えるだけの存在」から「自律して動く存在」に変わります。

**Desktop Commander は Anthropic 公式の旗艦 MCP ツールです。** Claude がファイルの読み書き・コマンド実行・git 操作・開発サーバー管理を自律的に行えるようになります。

### ⚠️ しかし！重大なセキュリティリスクが潜んでいる

デフォルト設定では Desktop Commander は AI にホームフォルダ全体へのアクセスを許可します。`~/.ssh`（SSH 秘密鍵）・`~/.aws`（クラウド認証）・全プロジェクトの `.env` が AI の射程内に入っています。

悪意あるプロンプトが1つ混入するだけで、**ユーザーの操作なしに**自動的に秘密鍵が外部送信されます。これが **Parasitic Toolchain Attack** です。

```
① 侵入（EIT） — Web ページ等の悪意ある命令が fetch 時に AI に混入
② 収集（PAT） — 汚染された AI が ~/.ssh / .env を自律的に読み取る
③ 漏洩（NAT） — curl 等で外部送信。ユーザー操作ゼロで完結
```

根本原因は LLM がデータと命令を区別できないという**パッチ不能な原理的弱点**です。だから「物理的に到達できない構造」を Docker で作ります。

### 解決策：Docker Shield

| 項目 | デフォルト DC | Docker Shield |
|---|---|---|
| `~/.ssh` SSH 秘密鍵 | 🔴 盗める | ✅ 物理的に不可能 |
| `~/.aws` クラウド認証 | 🔴 盗める | ✅ 物理的に不可能 |
| 他 PJT の `.env` | 🔴 盗める | ✅ 物理的に不可能 |
| `git push` / `gh pr create` | ⚙️ ホスト依存 | ✅ DC 内で完全動作 |
| 開発サーバー起動 | ⚙️ ホスト依存 | ✅ ポートマップで対応 |
| セッション毎の手動設定 | 🔴 毎回必要 | ✅ 不要（自動適用） |


### スライド資料

設計思想・攻撃手法・セットアップ手順を18枚のスライドで解説しています：

👉 **[Desktop Commander Docker Shield — 完全マニュアル（18枚スライド）](https://claude.ai/public/artifacts/56167086-2154-40b5-b4e8-d0b1025854bd)**

---

### ファイル構成

```
desktop_commander/
├── Dockerfile        # コンテナ定義（git, gh CLI, bash, curl 含む）
├── entrypoint.sh     # 起動スクリプト（設定自動適用 + git 認証解決）
├── build.sh          # イメージビルドスクリプト
├── dc-config.json    # blockedCommands 参照用テンプレート
└── dc-data/          # DC ランタイムデータ（.gitignore 済み）
```

### 事前準備

```bash
brew install gh
```

Docker Desktop をインストール（STEP 1 参照）

---

### STEP 0  リポジトリをクローンする

```bash
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander && mkdir -p dc-data
```

---

### STEP 1  Docker Desktop をインストールする

1. `https://www.docker.com/products/docker-desktop/` からダウンロード・インストール
2. 起動 →「Use recommended settings」→「Engine running」確認
3. **「バックグラウンドでの実行を許可」→ 必ず許可**
4. 歯車 > General >「Start Docker Desktop when you sign in」→ 自動起動 ON

> ⚠️ Claude Desktop より先に Docker Desktop が起動している必要があります。

---

### STEP 2  DXT をアンインストールする

1. Claude Desktop → 設定 > 拡張機能 > desktop-commander →「アンインストール」
2. **Cmd+Q で完全終了**（ウィンドウを閉じるだけでは不可）

---

### STEP 3  GitHub CLI の認証を設定する（重要）

```bash
gh auth login -h github.com --insecure-storage
```

- Protocol: **HTTPS** を選択
- Authentication: **Login with a web browser** を選択
- 表示された `XXXX-XXXX` コードをブラウザで入力
- `Authentication credentials saved in plain text` が出れば成功

> **なぜ `--insecure-storage` が必要か：** macOS のデフォルトでは gh トークンが Keychain に保存されます。Docker コンテナは Keychain にアクセスできないため、`~/.config/gh/hosts.yml` への保存が必須です。


### STEP 4  claude_desktop_config.json を編集する

```bash
open -e "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
```

`mcpServers` に以下を追加：

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
    "--network", "bridge",
    "desktop-commander:latest"
  ]
}
```

**ユーザー名確認：** `whoami` **｜ ポート：** 6000〜9999 から空きを選ぶ（`lsof -i :XXXX` で確認）

| マウント | 権限 | 意図 |
|---|---|---|
| `/Development` | 読み書き | AI の作業域（ここだけが射程） |
| `~/.config/gh` | `:ro` | gh 認証トークン（改ざん防止） |
| `~/.gitconfig` | `:ro` | git identity（改ざん防止） |
| `~/.ssh` | **なし** | SSH 秘密鍵を物理的に保護 |

---

### STEP 5  Docker イメージをビルドする

```bash
cd ~/Development/desktop_commander
bash build.sh desktop-commander:latest
```

---

### STEP 6  Claude Desktop を起動して確認する

1. Docker Desktop が起動していることを確認
2. Claude Desktop を起動 → 新しいチャット
3. `Desktop Commander の get_config を実行してください` と送信

| 確認項目 | 期待する値 |
|---|---|
| `isContainer` | `true` |
| `isDXT` | `false` |
| `allowedDirectories` | `["/Users/あなたのユーザー名/Development"]` |
| `blockedCommands` | `nc`・`ncat`・`scp` 等が含まれる |


### Docker Shield で使えるようになること

```bash
# git 操作（HTTPS 経由・DC 内から実行可能）
git add . && git commit -m "message" && git push

# GitHub CLI（DC 内から実行可能）
gh pr create && gh auth status

# 開発サーバー（ホストブラウザから localhost:XXXX でアクセス可）
npm run dev -- --port XXXX
```

> **SSH git（`git@github.com:...`）は使えません。** HTTPS（`https://github.com/...`）を使ってください。

---

### セキュリティ設計：3層防御

```
Layer 1: Docker 壁        ← 主防御（常に有効・迂回不能）
  └─ ~/.ssh, ~/.aws → マウントなし = 物理的にアクセス不能

Layer 2: allowedDirectories ← ソフトウェア的な柵
  └─ /Development 外へのアクセスを DC が拒否

Layer 3: blockedCommands    ← 出口フィルタ
  └─ nc, scp, ftp 等の送信系コマンドをブロック
```

**残存ギャップ：** `curl` は開放中。Production では `--network none` を検討。

---

### チェックリスト

**初回セットアップ**
- [ ] リポジトリをクローン・`dc-data` を作成
- [ ] Docker Desktop インストール・自動起動 ON
- [ ] DXT アンインストール（Cmd+Q で完全終了）
- [ ] `gh auth login -h github.com --insecure-storage` 完了
- [ ] `claude_desktop_config.json` 編集済み（4 マウント + ポート + DC_ALLOWED_DIR）
- [ ] `bash build.sh desktop-commander:latest` 成功
- [ ] `isContainer: true` + `allowedDirectories` が正しいパスで確認済み

---

### コントリビュート

Issue・PR 歓迎します。
- Linux / Windows 対応
- `--network none` モードでの開発サーバー運用事例
- 他 MCP サーバーへの Docker Shield 適用事例

---

### 作者

**Peaske** — Indie Hacker / AI-Driven Accelerator

- 🐦 X（Twitter）: [@peaske_en](https://x.com/peaske_en)
- 🏢 Organization: [AXSC Studio](https://github.com/AXSC-Studio)
- 📊 スライド資料: [18枚スライド](https://claude.ai/public/artifacts/56167086-2154-40b5-b4e8-d0b1025854bd)

⭐ **このリポジトリが役に立ったらスターをお願いします！MCP セキュリティの認知向上に繋がります。**

---

*MIT License — AXSC Studio*
