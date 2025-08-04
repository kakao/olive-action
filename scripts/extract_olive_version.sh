#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════════════════════════════"
echo "📦 STEP 9: OLIVE CLI Version 조회"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔍 Extracting OLIVE CLI version..."
OLIVE_VERSION=$(olive-cli --version 2>&1 | head -n1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
if [[ $OLIVE_VERSION == *"Unable to find"* ]] || [[ $OLIVE_VERSION == *"Error"* ]]; then
  OLIVE_VERSION="Version information unavailable"
fi

echo "version=$OLIVE_VERSION" >> $GITHUB_OUTPUT

mkdir -p /home/deploy/repository/.olive/1
echo "$OLIVE_VERSION" > /home/deploy/repository/.olive/1/olive_version.txt

echo "📦 OLIVE CLI Version: $OLIVE_VERSION"

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI Version 조회 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 