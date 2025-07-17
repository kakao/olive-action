#!/bin/bash
set -e

echo '📋 Step 4: Running component on repository...'

TEMP_LOG_FILE=$(mktemp)

if ! olive-cli component | tee "$TEMP_LOG_FILE"; then
  echo '❌ Olive CLI component 분석 실패: 에러가 발생했습니다.'
  rm -f "$TEMP_LOG_FILE"
  exit 1
fi

echo "컴포넌트 매핑 및 언매핑 의존성 정보 저장 중..."

MAPPING_SECTION=$(awk '
BEGIN { found=0; printing=0; content=""; }
/^=+$/ {
  if (found == 0 && (getline line) > 0) {
    if (line ~ /Mapping Components:/) {
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
    } else {
      print line;
    }
  } else if (found == 1 && printing == 1) {
    printing=0;
  }
}
END { print content; }
' "$TEMP_LOG_FILE")

UNMAPPING_SECTION=$(awk '
BEGIN { found=0; content=""; }
/^=+$/ {
  if ((getline line) > 0) {
    if (line ~ /Unmapping Dependencies:/) {
      found=1;
      content=$0 "\n" line "\n";
      if ((getline line) > 0) {
        content=content line "\n";
        while ((getline line) > 0 && line !~ /^=+$/) {
          content=content line "\n";
        }
        content=content line "\n";
        print content;
        exit;
      }
    }
  }
}
' "$TEMP_LOG_FILE")

mkdir -p .olive/1

echo "$MAPPING_SECTION" > .olive/1/mapping_components.txt

echo "$UNMAPPING_SECTION" > .olive/1/unmapping_dependencies.txt

rm -f "$TEMP_LOG_FILE"

echo '📂 .olive directory structure:' && ls -al .olive
echo '📁 .olive/1 contents:' && ls -al .olive/1 