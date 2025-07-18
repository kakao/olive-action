#!/bin/bash
set -e

INPUT_PROJECT_NAME=""
GITHUB_REPOSITORY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project-name)
      INPUT_PROJECT_NAME="$2"
      shift 2
      ;;
    --repository)
      GITHUB_REPOSITORY="$2"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

if [ -z "$INPUT_PROJECT_NAME" ]; then
  PROJECT_NAME=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
  echo "프로젝트 이름이 지정되지 않아 저장소 이름으로 자동 생성: $PROJECT_NAME"
else
  PROJECT_NAME="$INPUT_PROJECT_NAME"
  echo "지정된 프로젝트 이름 사용: $PROJECT_NAME"
fi
if [ -n "$GITHUB_OUTPUT" ] && [ -f "$GITHUB_OUTPUT" ]; then
  echo "project-name=$PROJECT_NAME" >> $GITHUB_OUTPUT
else
  echo "::set-output name=project-name::$PROJECT_NAME"
fi 