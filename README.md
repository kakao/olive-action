# OLIVE Action

**OLIVE Action**은 GitHub Actions에서 [OLIVE CLI](https://github.com/kakao/olive-cli)를 사용하여 오픈소스 라이선스 의무사항을 준수를 지원합니다.

이 Action을 통해 다음을 수행할 수 있습니다.

- **자동 의존성 분석**: Pull Request 생성시 소스코드 의존성을 분석합니다.

- **PR 코멘트 리포팅**: 분석 결과를 PR에 코멘트로 남겨 변경 사항을 바로 확인할 수 있습니다.

- **OLIVE Platform 연동**: 분석 결과를 [OLIVE Platform](https://olive.kakao.com/)으로 전송하여 오픈소스 라이선스 및 취약점을 관리합니다.

- **분석 결과 저장**: 상세 분석 결과는 GitHub Artifacts로 저장합니다.

> 이 Action은 Docker 컨테이너 환경에서 OLIVE CLI를 실행합니다.

## 사전 준비 (Prerequisites)

Action을 사용하기 전에, [OLIVE Platform](https://olive.kakao.com/)에서 **API 토큰**을 발급받아야 합니다.

1.  [OLIVE Platform 토큰 발급 가이드](https://olive.kakao.com/docs/my-page/token)를 참고하여 토큰을 발급합니다.

2.  발급받은 토큰을 저장소 secret 으로 추가합니다. (예시에서 사용한 이름은 `OLIVE_TOKEN` 입니다.)
    - (참고) [GitHub Actions에서 secret 사용하기](https://docs.github.com/ko/actions/security-guides/using-secrets-in-github-actions)

## 기본 사용법 (Quick Start)

아래는 `main` 또는 `develop` 브랜치로 Pull Request가 생성될 때마다 의존성을 분석하는 가장 기본적인 워크플로우 예시입니다.

[GitHub Actions 가이드](https://docs.github.com/en/actions/get-started/understanding-github-actions)를 참고하여 workflow를 작성하세요.
workflow는 저장소의 `.github/workflows/` 에 생성됩니다.

```yaml
name: OLIVE Action

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - develop
      - main

permissions:
  contents: read
  issues: write
  pull-requests: write

jobs:
  olive-scan:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run OLIVE Action
        uses: kakao/olive-action@v1
        with:
          olive-token: ${{ secrets.OLIVE_TOKEN }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## 입력값 (Inputs)

Action의 동작을 제어하기 위한 입력값입니다. `with` 키워드를 사용하여 설정할 수 있습니다.

| 이름                      | 설명                                                                                                 | 필수  | 기본값                                       |
| :------------------------ | :--------------------------------------------------------------------------------------------------- | :---: | :------------------------------------------- |
| `olive-token`             | [OLIVE Platform](https://olive.kakao.com/) API 토큰. <br/>GitHub Secrets에 저장하여 사용해야 합니다. | **Y** | -                                            |
| `github-token`            | PR에 코멘트를 작성하기 위한 GitHub 토큰입니다.<br/> `${{ secrets.GITHUB_TOKEN }}` 사용을 권장합니다. | **Y** | -                                            |
| `olive-project-name`      | OLIVE Platform에 등록될 프로젝트 이름입니다.                                                         |   N   | 저장소 이름<br/>(`kakao/olive`의 경우 olive) |
| `source-path`             | 분석할 소스코드의 루트 경로입니다.                                                                   |   N   | `./`                                         |
| `user-config-path`        | OLIVE CLI의 기본 설정을 덮어쓸 사용자 정의 `config` 파일의 경로입니다.                               |   N   | `""`                                         |
| `artifact-retention-days` | 생성된 아티팩트의 보관 기간(일)입니다.                                                               |   N   | `30`                                         |
| `comment-on-pr`           | `true`로 설정 시, PR에 분석 결과 코멘트를 작성합니다.                                                |   N   | `true`                                       |
| `analyze-only`            | `true`로 설정 시, 분석만 수행하고 결과를 OLIVE Platform에 전송하지 않습니다.                         |   N   | `false`                                      |

## 다양한 사용법 예시 (Advanced Usage)

### 1\. 입력값 설정하기

프로젝트 이름, 소스 경로, 아티팩트 보관 기간 등을 직접 지정할 수 있습니다.

```yaml
- name: Run OLIVE Action with custom settings
  uses: kakao/olive-action@v1
  with:
    olive-project-name: "my-custom-project"
    olive-token: ${{ secrets.OLIVE_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    source-path: "./src" # 분석할 소스코드 경로
    artifact-retention-days: "7" # 아티팩트 보관 기간 (일)
    comment-on-pr: "true" # PR에 코멘트 작성 여부
```

### 2\. 분석만 수행하기 (OLIVE Platform에 결과 미전송)

`analyze-only`를 `true`로 설정하면, OLIVE Platform에 프로젝트를 생성하거나 결과를 전송하지 않고 분석만 수행합니다.

```yaml
- name: Run OLIVE Action (analysis only)
  uses: kakao/olive-action@v1
  with:
    olive-token: ${{ secrets.OLIVE_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    analyze-only: "true"
```

### 3\. 사용자 정의 `config` 파일 사용하기

프로젝트에 사용자 정의 config 파일을 생성하여 OLIVE CLI의 세부 동작을 제어할 수 있습니다.
아래 예시는 프로젝트 루트에 `user-config.yml` 파일을 사용하는 경우 입니다.

```yaml
- name: Run OLIVE Action with custom config
  uses: kakao/olive-action@v1
  with:
    olive-token: ${{ secrets.OLIVE_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    user-config-path: "./user-config.yml"
```

**`user-config.yml` 파일 예시:**

```yaml
isOpenSource: false # 소스 코드 공개 여부 (기본값: false)
excludePaths: # 분석에서 제외할 경로 (기본값: 빈 목록)
  - "node_modules"
  - ".git"
  - "build"
analysisType: "PARSER" # Gradle 의존성 분석 방식 ("PARSER" 또는 "BUILDER", 기본값: "PARSER")
onlyDirect: false # 직접 의존성만 분석할지 여부 (기본값: false)
gradleBuildVariant: ""
# 분석할 Build Variant 지정 (예: "debug", "release", "freeDebug" 등, 기본값: "")
# 값이 비어 있으면 모든 Build Variant에 대한 의존성이 포함됩니다.
excludeGradle: # Gradle 빌드 수행 시 제외할 모듈 이름 목록 (기본값: 빈 목록)
  - ":test"
```

## 실행 결과 (Results)

Action이 성공적으로 실행되면 다음과 같은 결과를 확인할 수 있습니다.

### 1\. GitHub 아티팩트(Artifacts)

- **local-config.yaml**: Action 실행에 사용된 OLIVE CLI 설정 파일

- 의존성 분석 결과

  - `dependency.csv`, `dependency.json`

- 의존성을 OLIVE 컴포넌트에 매핑한 결과

  - `mapping.json` : 모든 데이터(매핑 및 매핑되지 않은 데이터 전체)의 모든 필드
  - `mapping.csv` : 매핑된 데이터의 정제된 필드
  - `unmapping.csv` : 매핑되지 않은 데이터의 정제된 필드

### 2\. Pull Request 코멘트

`comment-on-pr`이 `true`일 경우, PR에 아래 정보를 포함한 코멘트가 자동으로 생성되거나 업데이트됩니다.

- OLIVE CLI 버전 및 프로젝트 이름

- Action 실행 로그 링크

- 라이선스 및 컴포넌트 매핑 정보 요약

- 매핑되지 않은 의존성 목록

- 생성된 아티팩트 목록

## 참고사항

- **실패 가이드**: Action 실행이 실패하는 경우, [OLIVE Action 실패 가이드](https://olive.kakao.com/docs/olive-action/olive-action-error)를 참고하여 문제를 해결할 수 있습니다.

- **GitHub 정책**: 이 Action은 github.com에 정의된 GitHub Actions 정책을 따릅니다.

## 면책조항

카카오는 OLIVE Action을 통해 제공되는 모든 정보의 정확성, 신뢰도 등에 대해 어떠한 보증도 하지 않습니다.
사용자는 전적으로 자기 책임 하에 OLIVE Action과 OLIVE Platform 을 사용하고, 카카오는 이와 관련하여 사용자 및 제3자에 대해 어떠한 책임도 지지 않습니다.

## License

This software is licensed under the Apache 2 license, quoted below.

Copyright 2025 Kakao Corp. http://www.kakaocorp.com

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this project except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Quick Links
- 문의하기 : <a href="http://pf.kakao.com/_ztlfK/chat"><img src="https://t1.kakaocdn.net/together_image/svg/footer_kakaotalk.svg" height="16px" width="16px"></a>&nbsp;&nbsp;&nbsp;[✉](mailto:opensource@kakaocorp.com)
