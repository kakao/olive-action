#!/bin/bash
set -e 

echo "════════════════════════════════════════════════════════════════════════════════"
echo "🚀 STEP 6: OLIVE CLI Apply(OLIVE Platform 연동)"
echo "════════════════════════════════════════════════════════════════════════════════"
echo '📋 Running apply on repository...'
olive-cli apply

if [ $? -ne 0 ]; then
  echo '❌ OLIVE CLI apply 실패: 에러가 발생했습니다.'
  exit 1
fi

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI Apply(OLIVE Platform 연동) 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 