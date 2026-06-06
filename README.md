# 🛡️ Desktop Commander Docker Shield

[![GitHub stars](https://img.shields.io/github/stars/AXSC-Studio/desktop-commander?style=flat-square)](https://github.com/AXSC-Studio/desktop-commander/stargazers)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square)]()
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

**🌐 [🇺🇸 English](#-english) · [🇨🇳 中文](#-中文) · [🇯🇵 日本語](#-日本語)**

---

## 🇺🇸 English

### What is MCP?

MCP (Model Context Protocol) is the fastest-growing AI infrastructure standard in the world — adopted by 28% of Fortune 500 companies, powering 20,000+ servers with 97M+ monthly SDK downloads, and named the #1 IT Infrastructure Technology of 2026. Anthropic, OpenAI, Google, Amazon, and Microsoft have all rallied behind the same standard. It is the "USB-C of AI" — a universal connector that gives AI true hands and feet to operate autonomously.

### Desktop Commander — The #1 Community MCP Tool

**Desktop Commander** is an open-source MCP server (MIT, by Eduard Ruzga) officially recommended by Anthropic on their Claude plugin marketplace. It is the most widely used MCP tool for Claude Desktop. With it, Claude can read/write files, execute terminal commands, manage git repositories, and run dev servers — all autonomously.

### ⚠️ Critical Security Risk

By default, Desktop Commander gives Claude access to your **entire home directory** — including `~/.ssh` (SSH private keys) and `~/.aws` (cloud credentials). A single malicious prompt injected into any webpage Claude reads can silently exfiltrate your secrets. No user action required. This is the **Parasitic Toolchain Attack**.

```
① Inject  — Malicious instruction hidden in a webpage Claude fetches
② Collect — Compromised AI autonomously reads ~/.ssh, .env files
③ Exfil   — Data sent to attacker via curl. Zero user interaction.
```

The root cause is that LLMs cannot distinguish data from instructions — an unfixable architectural property. The solution is to make secrets **physically unreachable** using Docker.

### TL;DR

| | Default DC | Docker Shield |
|---|---|---|
| `~/.ssh` SSH keys | 🔴 Stealable | ✅ Physically impossible |
| `~/.aws` cloud creds | 🔴 Stealable | ✅ Physically impossible |
| Other projects' `.env` | 🔴 Stealable | ✅ Physically impossible |
| `git push` / `gh pr create` | ⚙️ Host only | ✅ Works inside DC |
| Dev server | ⚙️ Host only | ✅ Port-mapped |
| Manual session setup | 🔴 Every time | ✅ Auto-applied |


### Prerequisites

- macOS with [Homebrew](https://brew.sh) installed
- `brew install gh` (GitHub CLI)
- Docker Desktop (installed in STEP 1)

### STEP 0 — Clone the repository

```bash
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander && mkdir -p dc-data
```

### STEP 1 — Install Docker Desktop

1. Download from `https://www.docker.com/products/docker-desktop/`
2. Launch → "Use recommended settings" → Finish → Skip
3. Confirm "Engine running" in the bottom bar
4. **Allow background execution when prompted (required)**
5. Gear icon → General → enable "Start Docker Desktop when you sign in"

> ⚠️ Docker Desktop must start **before** Claude Desktop.

### STEP 2 — Uninstall DXT

1. Claude Desktop → Settings → Extensions → desktop-commander → Uninstall
2. **Quit completely with Cmd+Q** (closing the window is not enough)

### STEP 3 — Authenticate GitHub CLI (critical)

```bash
gh auth login -h github.com --insecure-storage
```

- Protocol → **HTTPS**
- Authentication → **Login with a web browser**
- Enter the `XXXX-XXXX` code shown in your terminal into the browser

> **Why `--insecure-storage`?** By default, macOS stores the gh token in Keychain. Docker containers cannot access Keychain, so the token must be stored in `~/.config/gh/hosts.yml` (a plain file). The container mounts this file as `:ro` (read-only), preventing tampering.

### STEP 4 — Edit claude_desktop_config.json

```bash
open -e "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
```

Add to `mcpServers` (replace `yourusername` and choose ports):

```json
"desktop-commander": {
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "-v", "/Users/yourusername/Development:/Users/yourusername/Development",
    "-v", "/Users/yourusername/Development/desktop_commander/dc-data:/root/.claude-server-commander",
    "-v", "/Users/yourusername/.config/gh:/root/.config/gh:ro",
    "-v", "/Users/yourusername/.gitconfig:/root/.gitconfig:ro",
    "-e", "DC_ALLOWED_DIR=/Users/yourusername/Development",
    "-p", "XXXX:XXXX",
    "--network", "bridge",
    "desktop-commander:latest"
  ]
}
```

Confirm your username: `whoami` — Choose ports from 6000–9999 to avoid conflicts.

| Mount | Permission | Purpose |
|---|---|---|
| `/Development` | read-write | AI's working directory |
| `~/.config/gh` | `:ro` | gh auth token (tamper-proof) |
| `~/.gitconfig` | `:ro` | git identity (tamper-proof) |
| `~/.ssh` | **not mounted** | SSH keys physically protected |


### STEP 5 — Build the Docker image

```bash
cd ~/Development/desktop_commander
bash build.sh desktop-commander:latest
# Expected: Build complete: desktop-commander:latest
```

### STEP 6 — Launch and verify

1. Start Claude Desktop (Docker Desktop must already be running)
2. Open a new chat and send: `Please run Desktop Commander's get_config`

| Check | Expected value |
|---|---|
| `isContainer` | `true` |
| `isDXT` | `false` |
| `allowedDirectories` | `["/Users/yourusername/Development"]` |
| `blockedCommands` | contains `nc`, `scp`, etc. |

### What you can now do inside DC (no terminal needed)

```bash
git add . && git commit -m "message" && git push
gh pr create && gh auth status
npm run dev -- --port XXXX   # accessible at localhost:XXXX in your browser
```

> **SSH git (`git@github.com:...`) is not supported.** Use HTTPS (`https://github.com/...`).

### Security Design

```
Layer 1: Docker wall        — Primary defense (always active, cannot be bypassed)
  └─ ~/.ssh, ~/.aws → not mounted = physically unreachable

Layer 2: allowedDirectories — Software fence
  └─ DC rejects access outside /Development

Layer 3: blockedCommands    — Exit filter
  └─ nc, scp, ftp, telnet blocked
```

**Residual gap:** `curl` is left open for health checks. In production, consider `--network none`.

### Checklist

- [ ] Cloned repo and created `dc-data/`
- [ ] Docker Desktop installed, running, auto-start ON
- [ ] DXT uninstalled (Cmd+Q to fully quit)
- [ ] `gh auth login -h github.com --insecure-storage` completed
- [ ] `claude_desktop_config.json` edited (4 mounts + port + DC_ALLOWED_DIR)
- [ ] `bash build.sh desktop-commander:latest` succeeded
- [ ] `isContainer: true` confirmed in get_config

### Contribute

Issues and PRs welcome: Linux/Windows support · `--network none` dev server setups · Docker Shield for other MCP servers

### Author

**Peaske** — Indie Hacker / AI-Driven Accelerator
🐦 [@peaske_en](https://x.com/peaske_en) · 🏢 [AXSC Studio](https://github.com/AXSC-Studio)

⭐ **Star this repo** to help spread MCP security awareness!

---

## 🇨🇳 中文

### 什么是 MCP？

MCP（模型上下文协议）是全球增长最快的 AI 基础设施标准。财富 500 强中 28% 的企业已采用，服务器数量超过 2 万个，月均 SDK 下载量达 9700 万次，荣获 2026 年度 IT 基础设施技术大奖第一名。Anthropic、OpenAI、Google、Amazon、Microsoft 在竞争态势下共同采用同一标准——在科技史上极为罕见。MCP 被称为"AI 界的 USB-C"，是让 AI 真正拥有"手脚"、能够自主操作计算机的通用连接标准。

### Desktop Commander — 社区 No.1 MCP 工具

**Desktop Commander** 是由 Eduard Ruzga 主导的开源 MCP 服务器（MIT 协议），已被 Anthropic 收录于官方 Claude 插件市场并推荐使用。通过它，Claude 可以自主读写文件、执行终端命令、管理 Git 仓库、启动开发服务器。

### ⚠️ 重大安全风险

默认情况下，Desktop Commander 允许 AI 访问您的**整个主目录**，包括 `~/.ssh`（SSH 私钥）和 `~/.aws`（云端凭证）。只要 Claude 读取了含有恶意提示词的网页，攻击就会自动完成——无需任何用户操作。这就是**寄生工具链攻击（Parasitic Toolchain Attack）**。

```
① 注入 — 恶意指令隐藏在 Claude 抓取的网页中
② 收集 — 被感染的 AI 自主读取 ~/.ssh、.env 等文件
③ 泄露 — 通过 curl 将数据发送给攻击者，全程零用户交互
```

根本原因是 LLM 无法区分数据与指令——这是无法修补的架构缺陷。解决方案是用 Docker 让密钥**在物理层面无法访问**。

### 对比

| | 默认 DC | Docker Shield |
|---|---|---|
| `~/.ssh` SSH 私钥 | 🔴 可被窃取 | ✅ 物理隔离 |
| `~/.aws` 云端凭证 | 🔴 可被窃取 | ✅ 物理隔离 |
| 其他项目的 `.env` | 🔴 可被窃取 | ✅ 物理隔离 |
| `git push` / `gh pr` | ⚙️ 依赖宿主机 | ✅ DC 内部完整运行 |
| 开发服务器 | ⚙️ 依赖宿主机 | ✅ 端口映射支持 |
| 每次会话手动配置 | 🔴 每次都需要 | ✅ 自动应用 |

### 环境准备

- macOS + [Homebrew](https://brew.sh)
- `brew install gh`（GitHub CLI）
- Docker Desktop（见 STEP 1）

### STEP 0 — 克隆仓库

```bash
git clone https://github.com/AXSC-Studio/desktop-commander.git ~/Development/desktop_commander
cd ~/Development/desktop_commander && mkdir -p dc-data
```


### STEP 1 — 安装 Docker Desktop

1. 从 `https://www.docker.com/products/docker-desktop/` 下载并安装
2. 启动 → "Use recommended settings" → Finish → Skip
3. 确认底部显示 "Engine running"
4. **允许后台运行（必须）**
5. 齿轮图标 → General → 勾选 "Start Docker Desktop when you sign in"

> ⚠️ Docker Desktop 必须在 Claude Desktop **之前**启动。

### STEP 2 — 卸载 DXT

1. Claude Desktop → 设置 → 扩展 → desktop-commander → 卸载
2. **使用 Cmd+Q 完全退出**（仅关闭窗口不够）

### STEP 3 — GitHub CLI 认证（重要）

```bash
gh auth login -h github.com --insecure-storage
```

- 协议选择 **HTTPS**
- 认证方式选择 **Login with a web browser**
- 在浏览器中输入终端显示的 `XXXX-XXXX` 代码
- 出现 `Authentication credentials saved in plain text` 即成功

> **为什么需要 `--insecure-storage`？** macOS 默认将 gh token 存入 Keychain。Docker 容器无法访问 Keychain，因此必须将 token 存储到 `~/.config/gh/hosts.yml`（文件形式）。容器以 `:ro`（只读）挂载该文件，防止篡改。

### STEP 4 — 编辑 claude_desktop_config.json

```bash
open -e "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
```

在 `mcpServers` 中添加以下内容（将 `用户名` 替换为实际用户名，选择可用端口）：

```json
"desktop-commander": {
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "-v", "/Users/用户名/Development:/Users/用户名/Development",
    "-v", "/Users/用户名/Development/desktop_commander/dc-data:/root/.claude-server-commander",
    "-v", "/Users/用户名/.config/gh:/root/.config/gh:ro",
    "-v", "/Users/用户名/.gitconfig:/root/.gitconfig:ro",
    "-e", "DC_ALLOWED_DIR=/Users/用户名/Development",
    "-p", "XXXX:XXXX",
    "--network", "bridge",
    "desktop-commander:latest"
  ]
}
```

确认用户名：`whoami` — 端口从 6000–9999 中选择空闲端口。

| 挂载路径 | 权限 | 用途 |
|---|---|---|
| `/Development` | 读写 | AI 的工作目录 |
| `~/.config/gh` | `:ro` | gh 认证 token（防篡改） |
| `~/.gitconfig` | `:ro` | git 身份信息（防篡改） |
| `~/.ssh` | **不挂载** | SSH 私钥物理保护 |


### STEP 5 — 构建 Docker 镜像

```bash
cd ~/Development/desktop_commander
bash build.sh desktop-commander:latest
# 预期输出：Build complete: desktop-commander:latest
```

### STEP 6 — 启动并验证

1. 确认 Docker Desktop 已运行
2. 启动 Claude Desktop → 新建对话
3. 发送：`请执行 Desktop Commander 的 get_config`

| 验证项 | 预期值 |
|---|---|
| `isContainer` | `true` |
| `isDXT` | `false` |
| `allowedDirectories` | `["/Users/用户名/Development"]` |
| `blockedCommands` | 包含 `nc`、`scp` 等 |

### Docker Shield 开启后可用的功能

```bash
# 在 DC 内部完整运行（无需终端）
git add . && git commit -m "message" && git push
gh pr create && gh auth status
npm run dev -- --port XXXX   # 在宿主机浏览器通过 localhost:XXXX 访问
```

> **不支持 SSH git（`git@github.com:...`）。** 请使用 HTTPS（`https://github.com/...`）。

### 安全设计：三层防护

```
第1层：Docker 隔离墙  — 主要防护（始终有效，无法绕过）
  └─ ~/.ssh、~/.aws → 未挂载 = 物理上无法访问

第2层：allowedDirectories — 软件围栏
  └─ DC 拒绝 /Development 以外的访问

第3层：blockedCommands — 出口过滤
  └─ 阻断 nc、scp、ftp 等传输类命令
```

**残留风险：** `curl` 保持开放（用于健康检查）。生产环境建议使用 `--network none`。

### 检查清单

- [ ] 已克隆仓库并创建 `dc-data/`
- [ ] Docker Desktop 已安装、运行、设置自动启动
- [ ] 已卸载 DXT（Cmd+Q 完全退出）
- [ ] 完成 `gh auth login -h github.com --insecure-storage`
- [ ] 已编辑 `claude_desktop_config.json`（4 个挂载 + 端口 + DC_ALLOWED_DIR）
- [ ] `bash build.sh desktop-commander:latest` 成功
- [ ] 已通过 get_config 确认 `isContainer: true`

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

**Desktop Commander は **Anthropic が公式プラグインページで推奨する** No.1 コミュニティ MCP ツールです。開発者は Eduard Ruzga 氏で、MIT ライセンスのオープンソース。Anthropic 製ではありませんが、Anthropic 公認のエコシステム推奨ツールです。** Claude がファイルの読み書き・コマンド実行・git 操作・開発サーバー管理を自律的に行えるようになります。

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

👉 **[Desktop Commander Docker Shield — 完全マニュアル（18枚スライド）](https://claude.ai/public/artifacts/c103b10c-a120-4d03-88c0-c14502f62745)**

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
- 📊 スライド資料: [18枚スライド](https://claude.ai/public/artifacts/c103b10c-a120-4d03-88c0-c14502f62745)

⭐ **このリポジトリが役に立ったらスターをお願いします！MCP セキュリティの認知向上に繋がります。**

---

*MIT License — AXSC Studio*
