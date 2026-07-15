#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════════════════════════════"
echo "🧩 STEP 4: OLIVE CLI Component 조회"
echo "════════════════════════════════════════════════════════════════════════════════"
echo '📋 Running component on repository...'

TEMP_LOG_FILE=$(mktemp)

if ! olive-cli component | tee "$TEMP_LOG_FILE"; then
  echo '❌ OLIVE CLI component 조회 실패: 에러가 발생했습니다.'
  rm -f "$TEMP_LOG_FILE"
  exit 1
fi

echo "컴포넌트 매핑 및 매핑되지 않은 의존성 정보 저장 중..."

MAPPING_SECTION=$(awk '
/^Mapping Components \(/ { found=1; content=$0 "\n"; next }
found && /^Unmapping Dependencies \(/ { exit }
found { content=content $0 "\n" }
END { printf "%s", content }
' "$TEMP_LOG_FILE")

UNMAPPING_SECTION=$(awk '
/^Unmapping Dependencies \(/ { found=1; content=$0 "\n"; next }
found { content=content $0 "\n" }
END { printf "%s", content }
' "$TEMP_LOG_FILE")

mkdir -p .olive/1

echo "$MAPPING_SECTION" > .olive/1/mapping_components.txt

echo "$UNMAPPING_SECTION" > .olive/1/unmapping_dependencies.txt

rm -f "$TEMP_LOG_FILE"

echo '📁 조회 결과 파일 조회: ls -al .olive/1:' && ls -al .olive/1
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI Component 조회 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 