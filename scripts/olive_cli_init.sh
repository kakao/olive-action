#!/bin/bash
set -e 

PROJECT_NAME=""
OLIVE_TOKEN=""
SOURCE_PATH=""
USER_CONFIG_PATH=""
DEBUG="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    --project-name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --olive-token)
      OLIVE_TOKEN="$2"
      shift 2
      ;;
    --source-path)
      SOURCE_PATH="$2"
      shift 2
      ;;
    --user-config-path)
      USER_CONFIG_PATH="$2"
      shift 2
      ;;
    --debug)
      DEBUG="$2"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔧 STEP 2: OLIVE CLI 초기화"
echo "════════════════════════════════════════════════════════════════════════════════"
echo '📋 Initializing OLIVE CLI...'

# debug 옵션 설정
DEBUG_OPTION=""
if [ "$DEBUG" = "true" ]; then
  DEBUG_OPTION="-d=true"
  echo "🐛 디버그 모드가 활성화되었습니다."
else
  echo "📝 일반 모드로 실행합니다."
fi

if [ -n "$USER_CONFIG_PATH" ] && [ -f "$USER_CONFIG_PATH" ]; then
  echo "🔧 사용자 정의 config 파일을 사용합니다: $USER_CONFIG_PATH"
  olive-cli init "$PROJECT_NAME" -t=$OLIVE_TOKEN -s $SOURCE_PATH -f $DEBUG_OPTION -c $USER_CONFIG_PATH
else
  echo "🔧 기본 설정으로 초기화합니다."
  olive-cli init "$PROJECT_NAME" -t=$OLIVE_TOKEN -s $SOURCE_PATH -f $DEBUG_OPTION
fi

if [ $? -ne 0 ]; then
  echo '❌ OLIVE CLI 초기화 실패: 에러가 발생했습니다.'
  exit 1
fi

echo '📁 초기화 결과 파일 조회: ls -al .olive' && ls -al .olive

LOCAL_CONFIG_FILE=".olive/local-config.yaml"

if [ -f "$LOCAL_CONFIG_FILE" ]; then
  # runIdUrl 추가
  RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  
  # scanInfo 섹션에 jdk17Home과 runIdUrl 추가
  # 먼저 resultPath 다음에 jdk17Home을 추가 (존재하지 않을 때만)
  # resultPath: 라인의 실제 들여쓰기를 감지하여 동일한 들여쓰기 적용
  INDENT=$(grep -m1 "resultPath:" "$LOCAL_CONFIG_FILE" | sed 's/[^ \t].*//')

  if ! grep -q "jdk17Home:" "$LOCAL_CONFIG_FILE"; then
    sed -i "/resultPath:/ a\\${INDENT}jdk17Home: /opt/openjdk-17" "$LOCAL_CONFIG_FILE"
  fi

  # runIdUrl이 이미 존재하는지 확인하고 값을 업데이트
  if grep -q "runIdUrl:" "$LOCAL_CONFIG_FILE"; then
    sed -i "s|[[:space:]]*runIdUrl:.*|${INDENT}runIdUrl: ${RUN_URL}|g" "$LOCAL_CONFIG_FILE"
  else
    sed -i "/jdk17Home:/ a\\${INDENT}runIdUrl: ${RUN_URL}" "$LOCAL_CONFIG_FILE"
  fi

  echo '📄 local-config.yaml 내용:'
  cat "$LOCAL_CONFIG_FILE"
else
  echo '⚠️ 경고: local-config.yaml 파일을 찾을 수 없습니다. jdk17Home 설정을 건너뜁니다.'
fi

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ OLIVE CLI 초기화 완료"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
