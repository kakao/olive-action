#!/bin/bash
set -e 

echo "════════════════════════════════════════════════════════════════════════════════"
echo "📄 STEP 5: OLIVE CLI License 조회"
echo "════════════════════════════════════════════════════════════════════════════════"
echo '📋 Running license on repository...'

TEMP_LOG_FILE=$(mktemp)

if ! olive-cli license | tee "$TEMP_LOG_FILE"; then
  echo '❌ OLIVE CLI license 분석 실패: 에러가 발생했습니다.'
  rm -f "$TEMP_LOG_FILE"
  exit 1
fi

echo "라이선스 정보 저장 중..."

LICENSE_SECTION=$(awk '
/^Licenses \(/ { found=1; content=$0 "\n"; next }
found { content=content $0 "\n" }
END { printf "%s", content }
' "$TEMP_LOG_FILE")

mkdir -p .olive/1

echo "$LICENSE_SECTION" > .olive/1/license_info.txt

rm -f "$TEMP_LOG_FILE"

echo '📁 조회 결과 파일 조회: ls -al .olive/1:' && ls -al .olive/1
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI License 조회 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 