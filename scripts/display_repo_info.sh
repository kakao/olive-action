#!/bin/bash
set -e

GITHUB_REPOSITORY=""
GITHUB_BRANCH=""
GITHUB_COMMIT=""
WORKSPACE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --repository)
      GITHUB_REPOSITORY="$2"
      shift 2
      ;;
    --ref_name)
      GITHUB_BRANCH="$2"
      shift 2
      ;;
    --sha)
      GITHUB_COMMIT="$2"
      shift 2
      ;;
    --workspace)
      WORKSPACE="$2"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

echo "📁 Repository: $GITHUB_REPOSITORY"
echo "🌿 Branch: $GITHUB_BRANCH"
echo "📋 Commit: $GITHUB_COMMIT"
echo "📊 Workspace contents:"
ls -la $WORKSPACE
echo "" 