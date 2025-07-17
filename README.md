# OLIVE CLI Scanner Action V1

Kakao OLIVE CLI를 사용하여 소스코드 의존성을 분석하고 PR에 결과를 코멘트로 남기는 GitHub Action입니다.  
이 액션은 Docker 컨테이너 환경에서 OLIVE CLI를 실행하여 프로젝트의 의존성을 분석하고, 분석 결과를 아티팩트로 저장하며, PR에 자동으로 결과를 코멘트로 작성합니다.

# What's new

| 버전 | 변경 사항                                                               |
| ---- | ----------------------------------------------------------------------- |
| V1   | 초기 버전 - OLIVE CLI 기반 의존성 분석, 아티팩트 업로드, PR 코멘트 기능 |

# Inputs

### `olive-project-name`

Olive 프로젝트 이름입니다. Default: 저장소 이름 (예: 'kakao/repo'의 경우 'repo')

### `olive-token`

**Required** OLIVE API 토큰입니다. (마이 페이지 > 토큰 설정에서 생성한 토큰) 반드시 GitHub Secrets에 저장하여 사용하세요.

### `github-token`

**Required** PR에 코멘트를 작성하기 위한 GitHub 토큰입니다. 일반적으로 `${{ secrets.GITHUB_TOKEN }}`을 사용합니다.

### `source-path`

분석할 소스코드 경로입니다. Default: `./`

### `artifact-retention-days`

아티팩트 보관 기간(일)입니다. Default: `30`

### `comment-on-pr`

PR에 코멘트 작성 여부입니다. Default: `true`

### `analyze-only`

분석만 수행하고 아티팩트 업로드/PR 코멘트를 생략할지 여부입니다. Default: `false`

# Example usage

## 기본 사용법 (PR에서 자동 실행)

```yaml
name: OLIVE CLI Scanner

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - develop
      - main

jobs:
  olive-scan:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run OLIVE CLI Scanner
        uses: kakao/olive-actions@v1
        with:
          olive-token: ${{ secrets.OLIVE_TOKEN }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## 커스터마이징 예시

```yaml
- name: Run OLIVE CLI Scanner with custom settings
  uses: kakao/olive-actions@v1
  with:
    olive-project-name: "my-custom-project"
    olive-token: ${{ secrets.OLIVE_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    source-path: "./src"
    artifact-retention-days: "7"
    comment-on-pr: "true"
```

## 분석만 수행 (아티팩트/코멘트 없이)

```yaml
- name: Run OLIVE CLI Scanner (analysis only)
  uses: kakao/olive-actions@v1
  with:
    olive-token: ${{ secrets.OLIVE_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    analyze-only: "true"
```

## 사용자 정의 config 파일 사용

```yaml
- name: Run OLIVE CLI Scanner with custom config
  uses: kakao/olive-actions@v1
  with:
    olive-token: ${{ secrets.OLIVE_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    user-config-path: "./user-config.yaml"
```

사용자 정의 config 파일(user-config.yaml) 예시:

```yaml
isOpenSource: true # 오픈소스 프로젝트 여부
excludePaths: # 분석에서 제외할 경로 목록
  - "node_modules"
  - ".git"
  - "build"
analysisType: "PARSER" # 분석 유형 설정 (PARSER: 소스코드 파서 기반 분석, BUILDER: 빌드 결과물 분석)
onlyDirect: false # 직접 의존성만 분석할지 여부 (false: 모든 의존성 분석)
gradleBuildVariant: "debug" # Gradle 프로젝트의 빌드 변형 설정
excludeGradle: # Gradle 분석 시 제외할 설정 목록
  - "testImplementation"
```

# 생성되는 아티팩트

이 액션은 다음과 같은 아티팩트를 생성합니다:

- **local-config.yaml**: OLIVE CLI 설정 파일
- **dependency-analysis**: 의존성 분석 결과
  - dependency.csv: CSV 형식의 의존성 목록
  - dependency.json: JSON 형식의 의존성 상세 정보
- **apply-analysis**: 적용 분석 결과
  - dependency.csv: CSV 형식의 적용 의존성 목록
  - dependency.json: JSON 형식의 적용 의존성 상세 정보
  - mapping.csv: CSV 형식의 적용 매핑 목록
  - mapping.json: JSON 형식의 적용 매핑 상세 정보
  - unmapping.csv: CSV 형식의 언매핑 목록

# PR 코멘트

PR에 자동으로 생성되는 코멘트는 다음 정보를 포함합니다:

- OLIVE CLI 버전
- 프로젝트 이름
- 상세 로그 링크
- OLIVE 분석 결과 링크
- 라이선스 정보
- 컴포넌트 매핑 정보
- 언매핑 의존성 정보

기존 코멘트가 있는 경우 업데이트되며, 없는 경우 새로 생성됩니다.

# 코드 구조

액션의 코드는 다음과 같이 구성되어 있습니다:

- **action.yml**: 액션의 메인 설정 파일
- **scripts/**: 각 스텝별 실행 스크립트
  - **display_repo_info.sh**: 저장소 정보 표시
  - **set_project_name.sh**: 프로젝트 이름 설정
  - **verify_source_location.sh**: 소스 위치 확인
  - **olive_cli_init.sh**: OLIVE CLI 초기화
  - **olive_cli_analyze.sh**: 기본 분석 실행
  - **olive_cli_component.sh**: 컴포넌트 분석 실행
  - **olive_cli_license.sh**: 라이선스 분석 실행
  - **olive_cli_apply.sh**: 적용 분석 실행
  - **extract_olive_version.sh**: OLIVE CLI 버전 추출
  - **get_artifact_info.sh**: 아티팩트 정보 가져오기
  - **comment_pr.js**: PR에 코멘트 작성
  - **cleanup.sh**: 컨테이너 정리
  - **finish.sh**: 작업 완료 메시지 출력

이러한 구조로 각 기능을 모듈화하여 유지보수성을 향상시켰습니다.

# Requirements

- 이 액션은 Docker가 실행 가능한 러너에서 실행되어야 합니다
- OLIVE API 토큰이 유효해야 합니다. [토큰 사용하기 안내 참고](https://olive.kakao.com/docs/my-page/token)

# Contributions

이슈나 PR은 언제든 환영합니다. 기여하실 때는 다음을 참고해주세요:

1. 이슈를 먼저 생성하여 논의해주세요
2. 변경사항에 대한 테스트를 포함해주세요
3. PR 설명에 변경 내용을 자세히 작성해주세요
