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
BEGIN { found=0; printing=0; content=""; }
/^=+$/ {
  if ((getline line) > 0) {
    if (line ~ /Licenses:/) {
      found=1;
      printing=1;
      content=content $0 "\n" line "\n";
      if ((getline line) > 0) {
        content=content line "\n";
        while ((getline line) > 0 && line !~ /^=+$/) {
          content=content line "\n";
        }
        content=content line "\n";
      }
    }
  } else if (found == 1 && printing == 1) {
    printing=0;
  }
}
END { print content; }
' "$TEMP_LOG_FILE")

mkdir -p .olive/1

echo "$LICENSE_SECTION" > .olive/1/license_info.txt

rm -f "$TEMP_LOG_FILE"

echo '📁 조회 결과 파일 조회: ls -al .olive/1:' && ls -al .olive/1

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI License 조회 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 