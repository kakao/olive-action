#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔗 OLIVE Platform Host 추출"
echo "════════════════════════════════════════════════════════════════════════════════"

CONFIG_FILE="/home/deploy/.olive/global-config.yaml"
OUTPUT_FILE="/home/deploy/repository/.olive_host_output"

if [ -f "$CONFIG_FILE" ]; then
  echo "📄 global-config.yaml 파일을 찾았습니다."
  
  # authInfo.host 값 추출
  HOST=$(grep -A3 "authInfo:" "$CONFIG_FILE" | grep "host:" | sed "s/.*host: *//" | tr -d "\"")
  
  if [ -n "$HOST" ]; then
    echo "✅ 추출된 host: $HOST"
    echo "$HOST" > "$OUTPUT_FILE"
  else
    echo "⚠️ host 추출 실패, 기본값 사용"
    echo "https://olive.kakao.com" > "$OUTPUT_FILE"
  fi
else
  echo "❌ global-config.yaml 파일이 없어 기본값 사용"
  echo "📄 찾고 있는 파일 경로: $CONFIG_FILE"
  echo "https://olive.kakao.com" > "$OUTPUT_FILE"
fi

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE Platform Host 추출 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 