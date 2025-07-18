#!/bin/bash
set -e

GITHUB_SERVER_URL=""
GITHUB_REPOSITORY=""
GITHUB_RUN_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --server-url)
      GITHUB_SERVER_URL="$2"
      shift 2
      ;;
    --repository)
      GITHUB_REPOSITORY="$2"
      shift 2
      ;;
    --run-id)
      GITHUB_RUN_ID="$2"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
if [ -n "$GITHUB_OUTPUT" ] && [ -f "$GITHUB_OUTPUT" ]; then
  echo "urls=$RUN_URL" >> $GITHUB_OUTPUT
else
  echo "::set-output name=urls::$RUN_URL"
fi 