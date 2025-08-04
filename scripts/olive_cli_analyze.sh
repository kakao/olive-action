#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════════════════════════════"
echo "📊 STEP 3: OLIVE CLI Analysis"
echo "════════════════════════════════════════════════════════════════════════════════"
echo '📋 Running analysis on repository...'
olive-cli analyze --mapping

if [ $? -ne 0 ]; then
  echo '❌ OLIVE CLI 분석 실패: 에러가 발생했습니다.'
  exit 1
fi

echo '📁 분석 결과 파일 조회: ls -al .olive/1:' && ls -al .olive/1

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI Analysis Complete"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 