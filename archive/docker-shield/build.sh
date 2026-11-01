#!/bin/bash
# Desktop Commander Docker イメージのビルドスクリプト
# 実行: bash build.sh [オプション: IMAGE_NAME]

set -e

IMAGE_NAME="${1:-desktop-commander:latest}"

echo "Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .
echo ""
echo "Build complete: $IMAGE_NAME"
echo ""
echo "次のステップ: README.md を参照して claude_desktop_config.json を更新してください。"
