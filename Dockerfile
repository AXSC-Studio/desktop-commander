# Desktop Commander - Docker Shield
# Peaske / AXSC 教材用
FROM node:22-alpine

# 開発に必要なツールを追加
RUN apk add --no-cache git github-cli coreutils bash curl

# Desktop Commander をインストール
RUN npm install -g @wonderwhy-er/desktop-commander

# 起動スクリプトをコピー
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
