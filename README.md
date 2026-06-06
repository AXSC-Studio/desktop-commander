# Desktop Commander セキュリティ強化 完全マニュアル

**対象:** AXSC 受講生 / Docker Shield 再現者  
**所要時間:** 約 45 分

---

## このマニュアルでやること

| 項目 | 変更前（デフォルト） | 変更後（Docker Shield） |
|---|---|---|
| 実行環境 | ホスト Mac 上で直接動作 | Docker コンテナ内で隔離 |
| ファイルアクセス範囲 | ホームフォルダ全体 | Development フォルダのみ |
| `~/.ssh`（SSH 秘密鍵） | 盗める | **物理的に不可能** |
| `~/.aws`（クラウド認証） | 盗める | **物理的に不可能** |
| git / GH CLI | ホスト依存 | **DC 内で完全動作** |
| 開発サーバー | ホスト依存 | ポートマップで対応 |
| セッション毎の手動設定 | 毎回必要 | **不要（自動適用）** |

---

## なぜ Docker が必要か

Desktop Commander は AI が自律的にファイル読み書き・コマンド実行を行えるツールです。
悪意あるプロンプトが混入すると `~/.ssh` や `.env` を読んで外部送信する
**Parasitic Toolchain Attack** が成立します。ユーザー操作は不要です。

Docker はコンテナという「檻」を設け、攻撃が成功しても鍵（`~/.ssh`）に
物理的に到達できない構造を作ります。

---

## ファイル構成（このリポジトリ）

```
desktop_commander/
├── Dockerfile        # コンテナ定義（git, gh CLI, bash, curl 含む）
├── entrypoint.sh     # 起動スクリプト（設定自動適用 + git 認証解決）
├── build.sh          # イメージビルドスクリプト
├── dc-config.json    # blockedCommands 参照用テンプレート
└── dc-data/          # DC ランタイムデータ（.gitignore 済み）
```

---

## 事前準備

- **gh CLI** がホスト Mac にインストール済みであること
  ```bash
  brew install gh
  ```
- **Docker Desktop** をインストール（後述 STEP 1）

---

## STEP 1  Docker Desktop をインストールする

1. `https://www.docker.com/products/docker-desktop/` からダウンロード・インストール
2. 起動 → 「Use recommended settings」→「Finish」→「Skip」
3. 画面下部に「Engine running」が表示されれば完了
4. **「バックグラウンドでの実行を許可」→ 必ず許可**

**自動起動設定（推奨）**
歯車アイコン > General >「Start Docker Desktop when you sign in」にチェック → Apply

> Claude Desktop より先に Docker Desktop が起動している必要があります。

---

## STEP 2  DXT をアンインストールする

1. Claude Desktop → 設定 > 拡張機能 > desktop-commander →「アンインストール」
2. **Cmd+Q で完全終了**（ウィンドウを閉じるだけでは不可）

---

## STEP 3  GitHub CLI の認証を設定する（重要）

DC コンテナ内から `git push` / `gh pr create` を使うために
`--insecure-storage` オプションでトークンをファイルに保存します。

```bash
gh auth login -h github.com --insecure-storage
```

- Protocol: **HTTPS** を選択
- Authentication: **Login with a web browser** を選択
- 表示された `XXXX-XXXX` コードをブラウザで入力
- `Authentication credentials saved in plain text` が出れば成功

> **なぜ `--insecure-storage` が必要か**
> macOS 標準設定では gh トークンが Keychain に保存されます。
> Docker コンテナは Keychain にアクセスできないため、
> `~/.config/gh/hosts.yml`（ファイル）への保存が必要です。
> コンテナは `:ro`（読み取り専用）でマウントするため書き換え不能です。

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
    "あなたのユーザー名/desktop-commander:latest"
  ]
}
```

**ユーザー名の確認:**
```bash
whoami
```

**ポート番号の選び方:**
`XXXX`〜`ZZZZ` には開発サーバーで使うポートを指定します。
よく使われる範囲（3000〜5999、8000〜8099）は競合しやすいため
6000〜9999 から空きを選ぶことを推奨します。

```bash
# 空きポートの確認例（3つの候補）
for port in 7432 7891 8743; do
  lsof -i :$port > /dev/null 2>&1 && echo "$port: 使用中" || echo "$port: 空き"
done
```

> **マウントの意味**
> | マウント | 権限 | 用途 |
> |---|---|---|
> | `/Development` | 読み書き | 作業ディレクトリ |
> | `~/.config/gh` | `:ro` | gh 認証トークン（読み取り専用） |
> | `~/.gitconfig` | `:ro` | git identity（読み取り専用） |
> | `~/.ssh` | **マウントなし** | SSH 秘密鍵を保護 |

---

## STEP 5  Docker イメージをビルドする

```bash
cd /Users/あなたのユーザー名/Development/desktop_commander
bash build.sh あなたのユーザー名/desktop-commander:latest
```

以下が表示されれば成功：

```
Build complete: あなたのユーザー名/desktop-commander:latest
```

> Dockerfile を変更した場合は必ず再実行すること。

---

## STEP 6  Claude Desktop を起動して確認する

1. Claude Desktop を起動（Docker Desktop が先に起動していること）
2. 新しいチャットを開く
3. 以下を入力：

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
# git 操作（HTTPS 経由・DC 内から実行可能）
git add . && git commit -m "message" && git push

# GitHub CLI（DC 内から実行可能）
gh pr create
gh auth status

# 開発サーバー（ポートマップ経由でホストブラウザからアクセス可）
npm run dev -- --port XXXX
curl http://localhost:XXXX
```

> **SSH git（`git@github.com:...`）は使えません。**
> HTTPS（`https://github.com/...`）を使ってください。
> 現代の開発では HTTPS + gh auth が標準です。

---

## セキュリティ設計：3層防御

```
[Docker 壁]          主防御（常に有効・迂回不能）
  └ ~/.ssh, ~/.aws, 他PJTの .env → 物理的にアクセス不能

[allowedDirectories] ソフトウェア的な柵
  └ コンテナ内での /Development 外アクセスを制限

[blockedCommands]    出口フィルタ
  └ nc, scp, ftp 等の送信系コマンドを遮断
```

**残存ギャップ:** `curl` はヘルスチェックのため開放しています。
`/Development` 内の `.env` は理論上 curl で外部送信可能です。
Production 環境では `--network none` の使用を検討してください。

---

## entrypoint.sh が起動時に自動実行すること

毎回の手動設定は不要です。コンテナ起動ごとに以下が自動適用されます。

1. `allowedDirectories` を `DC_ALLOWED_DIR` のパスに設定
2. `blockedCommands` に nc / scp / ftp 等を設定
3. macOS Homebrew の gh パスをコンテナ内 gh へリンク（git credential 解決）

---

## トラブルシューティング

| 症状 | 確認事項 |
|---|---|
| DC が反応しない | Docker Desktop が起動しているか確認 |
| `isContainer: false` | DXT が再インストールされていないか確認 |
| `allowedDirectories: []` | config.json に `DC_ALLOWED_DIR` が設定されているか確認 |
| `git push` が失敗 | `gh auth status` で `✓ Logged in` を確認。失敗なら STEP 3 を再実行 |
| build.sh でエラー | Docker Desktop の Engine が Running か確認 |

---

## チェックリスト

**初回セットアップ**
- [ ] Docker Desktop インストール・起動済み
- [ ] 「ログイン時に自動起動」設定 ON
- [ ] DXT アンインストール済み
- [ ] `gh auth login -h github.com --insecure-storage` 完了
- [ ] `claude_desktop_config.json` 編集済み（4 マウント + ポート + DC_ALLOWED_DIR）
- [ ] `bash build.sh あなたのユーザー名/desktop-commander:latest` 成功
- [ ] `isContainer: true` + `allowedDirectories` が正しいパスで確認済み

**日常運用**
- [ ] Claude Desktop を開く前に Docker Desktop が起動していることを確認
- [ ] gh トークン期限切れの場合は `gh auth login -h github.com --insecure-storage` を再実行

---

*Peaske / AXSC*
