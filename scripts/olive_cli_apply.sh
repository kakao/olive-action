#!/bin/bash
set -e 

echo '📋 Step 5: Running apply on repository...'
olive-cli apply

if [ $? -ne 0 ]; then
  echo '❌ Olive CLI apply 분석 실패: 에러가 발생했습니다.'
  exit 1
fi

echo '📂 .olive directory structure:' && ls -al .olive
echo '📁 .olive/1 contents:' && ls -al .olive/1 