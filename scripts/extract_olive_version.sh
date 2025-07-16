#!/bin/bash

echo "🔍 Extracting Olive CLI version..."
OLIVE_VERSION=$(olive-cli --version 2>&1 | head -n1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
if [[ $OLIVE_VERSION == *"Unable to find"* ]] || [[ $OLIVE_VERSION == *"Error"* ]]; then
  OLIVE_VERSION="Version information unavailable"
fi

# GitHub Actions 출력 변수에 저장
echo "version=$OLIVE_VERSION" >> $GITHUB_OUTPUT

# 버전 정보를 파일로도 저장
mkdir -p /home/deploy/repository/.olive/1
echo "$OLIVE_VERSION" > /home/deploy/repository/.olive/1/olive_version.txt

echo "📦 Olive CLI Version: $OLIVE_VERSION" 