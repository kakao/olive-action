#!/bin/bash
set -e 

PROJECT_NAME=""
OLIVE_TOKEN=""
SOURCE_PATH=""
ENVIRONMENT=""
USER_CONFIG_PATH=""

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
    --environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --user-config-path)
      USER_CONFIG_PATH="$2"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

echo '📋 Step 2: Initializing Olive CLI...'

if [ -n "$USER_CONFIG_PATH" ] && [ -f "$USER_CONFIG_PATH" ]; then
  echo "🔧 사용자 정의 config 파일을 사용합니다: $USER_CONFIG_PATH"
  olive-cli init "$PROJECT_NAME" -t=$OLIVE_TOKEN -s $SOURCE_PATH -f -d -c $USER_CONFIG_PATH
else
  echo "🔧 기본 설정으로 초기화합니다."
  olive-cli init "$PROJECT_NAME" -t=$OLIVE_TOKEN -s $SOURCE_PATH -f -d
fi

if [ $? -ne 0 ]; then
  echo '❌ Olive CLI 초기화 실패: 에러가 발생했습니다.'
  exit 1
fi

echo '✅ .olive folder contents:' && ls -al .olive

CONFIG_FILE="/home/deploy/.olive/global-config.yaml"
LOCAL_CONFIG_FILE=".olive/local-config.yaml"

# local-config.yaml 파일에 jdk11Home 설정 추가
if [ -f "$LOCAL_CONFIG_FILE" ]; then
  echo '✅ local-config.yaml 파일을 찾았습니다. jdk11Home 설정을 추가합니다.'
  
  echo '📄 변경 전 local-config.yaml 내용:'
  cat "$LOCAL_CONFIG_FILE" | grep -A3 'scanInfo:'
  
  # scanInfo 섹션에 jdk11Home 추가
  sed -i '/scanInfo:/,/executed:/ s|^\( *\)executed: .*|\1executed: null\n\1jdk11Home: /opt/openjdk-11|' "$LOCAL_CONFIG_FILE"
  
  echo '📄 변경 후 local-config.yaml 내용:'
  cat "$LOCAL_CONFIG_FILE" | grep -A4 'scanInfo:'
else
  echo '⚠️ 경고: local-config.yaml 파일을 찾을 수 없습니다. jdk11Home 설정을 건너뜁니다.'
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo '⚠️ 경고: global-config.yaml 파일을 찾을 수 없습니다. 환경 설정을 건너뜁니다.'
else
  echo '✅ global-config.yaml 파일을 찾았습니다. 환경 설정을 진행합니다.'
  
  echo '📄 변경 전 global-config.yaml 내용:'
  cat "$CONFIG_FILE" | grep -A3 'authInfo:'
  
  if [ "$ENVIRONMENT" = "dev" ]; then
    echo '🔧 Configuring for DEV environment...'
    sed -i '/authInfo:/,/apiToken:/ s|^\( *\)server: .*|\1server: "https://olive-api-dev.devel.kakao.com"|' "$CONFIG_FILE"
    sed -i '/authInfo:/,/apiToken:/ s|^\( *\)host: .*|\1host: "https://olive-dev.devel.kakao.com"|' "$CONFIG_FILE"
    echo '✅ DEV 환경으로 설정되었습니다.'
  elif [ "$ENVIRONMENT" = "sandbox" ]; then
    echo '🔧 Configuring for SANDBOX environment...'
    sed -i '/authInfo:/,/apiToken:/ s|^\( *\)server: .*|\1server: "https://olive-api-sandbox.devel.kakao.com"|' "$CONFIG_FILE"
    sed -i '/authInfo:/,/apiToken:/ s|^\( *\)host: .*|\1host: "https://olive-sandbox.devel.kakao.com"|' "$CONFIG_FILE"
    echo '✅ SANDBOX 환경으로 설정되었습니다.'
  else
    echo '✅ PROD 환경으로 설정되었습니다. (기본값)'
  fi
  
  echo '📄 변경 후 global-config.yaml 내용:'
  cat "$CONFIG_FILE" | grep -A3 'authInfo:'
  echo ''
  echo '📄 proxyInfo 설정 확인:'
  cat "$CONFIG_FILE" | grep -A3 'proxyInfo:'
fi 