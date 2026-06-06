# Desktop Commander セキュリティ設定マニュアル
**対象:** AXSC 受講生
**難易度:** 初級（コマンドのコピペのみ）
**所要時間:** 約 30 分

---

## このマニュアルでやること

Desktop Commander（DC）をより安全な構成に変更します。
変更前後の違いはこうなります：

| 項目 | 変更前（デフォルト） | 変更後（このマニュアル） |
|---|---|---|
| 実行環境 | ホスト Mac 上で直接動作 | Docker コンテナ内で動作 |
| ファイルアクセス範囲 | ホームフォルダ全体 | Development フォルダのみ |
| 危険コマンド | 野放し | ブロック済み |

---

## 事前知識：なぜ Docker が必要か

Desktop Commander は AI（Claude）がファイルを読み書きし、ターミナルコマンドを実行できるツールです。
悪意あるプロンプトが混入すると、AI が勝手に `~/.ssh`（SSH 秘密鍵）や `.env`（API キー）を読んで
外部に送信する攻撃（Parasitic Toolchain Attack）が成立します。

Docker を使うと、AI の動作がコンテナという「檻」の中に閉じ込められます。
外に出ようとしても物理的に不可能な構造になります。

```
攻撃が成功しても...
  コンテナ内から ~/.ssh へのアクセス → 不可能（マウントされていない）
  コンテナ内から外部への curl 送信  → blockedCommands でブロック
```

---

## STEP 0  準備：フォルダ構成を確認する

ターミナルで以下を実行してフォルダが存在するか確認します：

```bash
ls /Users/あなたのユーザー名/Development/desktop_commander/
```

以下のファイルが揃っていれば OK です：

```
Dockerfile
build.sh
dc-config.json
MANUAL.md（このファイル）
dc-data/（空のフォルダ）
```

ない場合は講師に確認してください。

---

## STEP 1  Docker Desktop をインストールする

1. ブラウザで以下を開く：
   `https://www.docker.com/products/docker-desktop/`

2. 「Download for Mac」をクリックしてインストール

3. インストール後に Docker Desktop を起動する

4. 「Finish setting up Docker Desktop」画面が出たら
   「Use recommended settings」を選択して「Finish」

5. 「Welcome to Docker」画面は右上の「Skip」をクリック

6. 画面下部に「Engine running」と表示されれば起動完了

**macOS から「バックグラウンドでの実行を許可」を求められたら必ず「許可」する（必須）**

### Docker を PC 起動時に自動起動する設定（推奨）

Docker Desktop の右上の歯車アイコン > General >
「Start Docker Desktop when you sign in to your computer」にチェックを入れて Apply

**重要：Claude Desktop より先に Docker Desktop が起動している必要があります。**
自動起動設定にしておくと PC 再起動後も問題なく動きます。

---

## STEP 2  DXT をアンインストールする

1. Claude Desktop を開く
2. 設定（左下のアイコン）> 拡張機能 > desktop-commander
3. 「アンインストール」ボタンをクリック
4. Claude Desktop を **Cmd+Q で完全終了**する

---

## STEP 3  claude_desktop_config.json を編集する

ターミナルで以下を実行してファイルを開く：

```bash
open -e "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
```

テキストエディットで開いたら **Cmd+A（全選択）→ 貼り付け → Cmd+S（保存）** で以下に置き換える：

```json
{
  "mcpServers": {
    "desktop-commander": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/Users/あなたのユーザー名/Development:/Users/あなたのユーザー名/Development",
        "-v", "/Users/あなたのユーザー名/Development/desktop_commander/dc-data:/root/.claude-server-commander",
        "--network", "bridge",
        "あなたのユーザー名/desktop-commander:latest"
      ]
    }
  }
}
```

**注意：「あなたのユーザー名」を実際のユーザー名に書き換えること。**
ターミナルで `whoami` を実行すると確認できます。

他の MCP サーバー（cleeean、develonica-io 等）がある場合は
`mcpServers` の中に追加する形で記述してください。

---

## STEP 4  Docker イメージをビルドする

ターミナルで以下を順番に実行：

```bash
cd /Users/あなたのユーザー名/Development/desktop_commander
bash build.sh
```

以下が表示されれば成功：

```
Build complete: あなたのユーザー名/desktop-commander:latest
```

---

## STEP 5  Claude Desktop を再起動して動作確認する

1. Claude Desktop を起動する（Docker Desktop が先に起動していること）
2. 新しいチャットを開く
3. 以下を入力して確認する：

```
Desktop Commander の get_config を実行してください
```

以下を確認する：

| 確認項目 | 期待する値 |
|---|---|
| `platform` | `Linux (Docker)` |
| `isContainer` | `true` |
| `isDXT` | `false` |
| `mountPoints` | `/Users/.../Development` が含まれる |

---

## STEP 6  セッション開始時の設定（毎回必要）

**既知の制限：** Docker コンテナは起動のたびに設定がリセットされます。
これは DC の設計仕様です。ただし Docker のボリュームマウントにより
コンテナ外（`~/.ssh` 等）へのアクセスは物理的に遮断されているため、実害はありません。

セッション開始時に以下の 2 つを依頼する習慣をつけてください：

```
Desktop Commander の allowedDirectories を
["/Users/あなたのユーザー名/Development"] に設定してください
```

```
Desktop Commander の blockedCommands に
nc, ncat, netcat, scp, sftp, ftp, telnet を追加してください
（既存リストは保持したまま）
```

---

## 理解しておくべき重要ポイント

### blockedCommands と「確認する」の違い

| 設定 | 動作 | 日常作業への影響 |
|---|---|---|
| `blockedCommands` | コマンドを完全に拒否 | 対象コマンドを使わなければゼロ |
| GUI「確認する」 | 実行前に毎回承認が必要 | 承認ダイアログが頻繁に出る |

`nc`（netcat）や `scp` は通常の Web 開発では使わないので
`blockedCommands` に追加しても開発の邪魔になりません。

### なぜ拡張機能に Desktop Commander が表示されないか

DXT（拡張機能）と MCP Server は別物です。
このマニュアルで設定した DC は `claude_desktop_config.json` に記述された
外部プロセスとして動くため、設定 > 拡張機能 の画面には表示されません。
これは正常な動作です。

### Docker のボリュームマウントが主な防御

```
allowedDirectories = ソフトウェア的な柵（リセットされることがある）
Docker ボリュームマウント = 物理的な壁（常に有効）
```

`allowedDirectories` がリセットされても
コンテナ内には `/Development` しかマウントされていないため
`~/.ssh`、`~/.aws` 等には物理的にアクセスできません。

---

## トラブルシューティング

| 症状 | 確認事項 |
|---|---|
| DC がチャットで反応しない | Docker Desktop が起動しているか確認 |
| `isContainer: false` が返る | DXT が再インストールされていないか確認 |
| `allowedDirectories: []` が返る | STEP 6 の設定コマンドを実行する |
| build.sh でエラー | Docker Desktop の Engine が running か確認 |

---

## チェックリスト

- [ ] Docker Desktop インストール・起動済み
- [ ] 「ログイン時に自動起動」設定 ON
- [ ] DXT アンインストール済み
- [ ] `claude_desktop_config.json` 編集済み（ユーザー名を正しく書き換えた）
- [ ] `docker build` 成功
- [ ] Claude Desktop 再起動後に `get_config` で `isContainer: true` を確認
- [ ] セッション開始時の `allowedDirectories` 設定を習慣化

---

## Docker 化後の使い分け（重要）

Docker 化により、DC（コンテナ内）とターミナルの役割分担が明確になった。

### DC（コンテナ）でやること
- ファイルの読み書き・コード編集
- ファイル検索・内容確認
- Claude へのコマンド提案依頼

### ターミナルでやること

| 操作 | 理由 |
|---|---|
| `git add / commit / push` | 認証情報（~/.ssh）がコンテナ外 |
| `gh pr create` 等 GitHub CLI | ~/.config/gh がコンテナにマウントされていない |
| `npm run dev` 等サーバー起動 | コンテナの localhost ≠ ホストの localhost |
| restart.sh 等の起動スクリプト | 上記ポート問題と同様 |

### 運用パターン
Claude がコマンドを提案 → **あなたがターミナルで実行**。

DC は「コードアシスタント」、ターミナルは「システムオペレーター」として使い分ける。git 認証情報や開発サーバーのポートはホスト側に置いたまま、セキュリティを維持する。
