#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔐 STEP 1: 필수 토큰 유효성 확인"
echo "════════════════════════════════════════════════════════════════════════════════"

GITHUB_TOKEN=""
OLIVE_TOKEN=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --github-token)
      GITHUB_TOKEN="$2"
      shift 2
      ;;
    --olive-token)
      OLIVE_TOKEN="$2"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

echo "🔐 필수 토큰 확인 중..."

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ github-token이 설정되지 않았습니다."
  echo ""
  echo "📋 해결 방법:"
  echo "1. workflow 파일에서 github-token을 설정해주세요:"
  echo "   with:"
  echo "     github-token: \${{ secrets.GITHUB_TOKEN }}"
  echo ""
  exit 1
fi

if [ -z "$OLIVE_TOKEN" ]; then
  echo "❌ olive-token이 설정되지 않았습니다."
  echo ""
  echo "📋 해결 방법:"
  echo "1. Repository Settings > Secrets and variables > Actions로 이동"
  echo "2. New repository secret을 클릭"
  echo "3. Name: OLIVE_TOKEN, Value: OLIVE Platform API 토큰 토큰 입력"
  echo "4. workflow 파일에서 다음과 같이 설정:"
  echo "   with:"
  echo "     olive-token: \${{ secrets.OLIVE_TOKEN }}"
  echo ""
  echo "🔗 OLIVE Platform API 토큰 발급: https://olive.kakao.com"
  echo ""
  exit 1
fi

echo "✅ 모든 필수 토큰이 설정되었습니다."

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ 필수 토큰 유효성 확인 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo "" 