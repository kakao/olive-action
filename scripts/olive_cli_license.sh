#!/bin/bash
set -e 

echo '📋 Step 5: Running license on repository...'

# 로그 출력을 파일로 캡처하기 위한 임시 파일
TEMP_LOG_FILE=$(mktemp)

# olive-cli license 실행 및 로그 저장
if ! olive-cli license | tee "$TEMP_LOG_FILE"; then
  echo '❌ Olive CLI license 분석 실패: 에러가 발생했습니다.'
  rm -f "$TEMP_LOG_FILE"
  exit 1
fi

echo "라이선스 정보 저장 중..."

# 라이선스 정보 추출 - 테이블 전체를 추출
# 시작 패턴과 끝 패턴 사이의 모든 내용을 추출
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

# 파일 저장 경로 생성
mkdir -p .olive/1

# 라이선스 정보 저장
echo "$LICENSE_SECTION" > .olive/1/license_info.txt

# 임시 파일 삭제
rm -f "$TEMP_LOG_FILE"

echo '📂 .olive directory structure:' && ls -al .olive
echo '📁 .olive/1 contents:' && ls -al .olive/1 