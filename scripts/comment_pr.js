module.exports = async ({ github, context, core }) => {
  const fs = require("fs")

  const inputData = getInputData(core)
  console.log("🔍 inputData 객체:", inputData)
  console.log("🔍 inputData.host:", inputData.host)

  const {
    oliveCliVersion,
    mappingComponentsInfo,
    unmappingDependenciesInfo,
    licenseInfo,
    hasLicenseIssue,
    hasLicenses,
  } = await readOliveData(fs, inputData.oliveCliVersion)

  const oliveScanUrl = await generateOliveScanUrl(fs, core)

  const commentBody = generateCommentBody({
    oliveCliVersion: oliveCliVersion,
    projectName: inputData.projectName,
    runUrl: inputData.runUrl,
    oliveScanUrl,
    licenseInfo,
    hasLicenseIssue,
    hasLicenses,
    mappingComponentsInfo,
    unmappingDependenciesInfo,
  })

  await createOrUpdateComment(github, context, commentBody)
}

/**
 * GitHub Actions에서 입력값 가져오기
 * @param {Object} core - @actions/core 객체
 * @returns {Object} 입력값 객체
 */
function getInputData(core) {
  return {
    oliveCliVersion: core.getInput("olive-version") || "Unknown",
    runUrl: core.getInput("run-url"),
    projectName: core.getInput("project-name"),
    host: core.getInput("host"),
  }
}

/**
 * OLIVE Action 결과 파일에서 읽기
 * @param {Object} fs - Node.js fs 모듈
 * @param {string} defaultVersion - 기본 OLIVE CLI 버전
 * @returns {Object} OLIVE Action 분석 결과 데이터 객체
 */
async function readOliveData(fs, defaultVersion) {
  let oliveCliVersion = defaultVersion
  let mappingComponentsInfo = "정보를 불러올 수 없습니다."
  let unmappingDependenciesInfo = "정보를 불러올 수 없습니다."
  let licenseInfo = "정보를 불러올 수 없습니다."
  let hasLicenseIssue = false
  let hasLicenses = false

  try {
    if (fs.existsSync(".olive/1/olive_version.txt")) {
      oliveCliVersion = fs.readFileSync(".olive/1/olive_version.txt", "utf8").trim()
      console.log("📦 파일에서 읽은 OLIVE CLI 버전:", oliveCliVersion)
    } else {
      console.log("⚠️ 버전 정보 파일을 찾을 수 없습니다. 기본값 사용:", oliveCliVersion)
    }

    mappingComponentsInfo = readFileWithFallback(
      fs,
      ".olive/1/mapping_components.txt",
      "정보를 불러올 수 없습니다."
    )

    unmappingDependenciesInfo = readFileWithFallback(
      fs,
      ".olive/1/unmapping_dependencies.txt",
      "정보를 불러올 수 없습니다."
    )

    const licenseResult = analyzeLicenseInfo(fs)
    licenseInfo = licenseResult.licenseInfo
    hasLicenseIssue = licenseResult.hasLicenseIssue
    hasLicenses = licenseResult.hasLicenses
  } catch (error) {
    console.error("파일 읽기 오류:", error)
  }

  return {
    oliveCliVersion: oliveCliVersion,
    mappingComponentsInfo,
    unmappingDependenciesInfo,
    licenseInfo,
    hasLicenseIssue,
    hasLicenses,
  }
}

/**
 * 파일 내용 읽기 (없으면 기본값 반환)
 * @param {Object} fs - Node.js fs 모듈
 * @param {string} filePath - 파일 경로
 * @param {string} defaultValue - 기본값
 * @returns {string} 파일 내용 또는 기본값
 */
function readFileWithFallback(fs, filePath, defaultValue) {
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath, "utf8").trim()
    return content.replace(/^\s*[\r\n]/gm, "")
  }
  return defaultValue
}

/**
 * 라이선스 정보 분석
 * @param {Object} fs - Node.js fs 모듈
 * @returns {Object} 라이선스 분석 결과
 */
function analyzeLicenseInfo(fs) {
  let licenseInfo = "정보를 불러올 수 없습니다."
  let hasLicenseIssue = false
  let hasLicenses = false

  if (fs.existsSync(".olive/1/license_info.txt")) {
    licenseInfo = fs.readFileSync(".olive/1/license_info.txt", "utf8").trim()
    licenseInfo = licenseInfo.replace(/^\s*[\r\n]/gm, "")

    hasLicenses = !licenseInfo.includes("Licenses (0)")

    if (hasLicenses) {
      hasLicenseIssue = checkLicenseIssues(licenseInfo)
      console.log("라이선스 이슈 확인:", hasLicenseIssue ? "이슈 있음" : "이슈 없음")
    } else {
      console.log("라이선스가 발견되지 않았습니다.")
    }
  }

  return { licenseInfo, hasLicenseIssue, hasLicenses }
}

/**
 * 이슈가 있는 라이선스 확인
 * @param {string} licenseInfo - 라이선스 정보 문자열
 * @returns {boolean} 이슈 존재 여부
 */
function checkLicenseIssues(licenseInfo) {
  try {
    // 라이선스 테이블에서 각 행을 분석
    const lines = licenseInfo.split("\n")

    for (const line of lines) {
      // 테이블 데이터 행인지 확인 (│ 로 시작하고 숫자 ID가 있는 행, Go CLI 형식)
      if (/^\s*│\s*\d+\s*│/.test(line)) {
        // │ (U+2502)로 구분된 컬럼들을 분리하고 빈 셀 제거
        const cells = line.split("│").map((col) => col.trim()).filter((col) => col !== "")

        // cells: ["1", "Apache-2.0", "X", "url", "obligations"]
        // isIssued 컬럼은 3번째 컬럼 (인덱스 2)
        if (cells.length >= 3) {
          const isIssued = cells[2]

          // isIssued 컬럼에 "O" 또는 "0"이 있으면 이슈가 있는 라이선스
          if (isIssued === "O" || isIssued === "0") {
            console.log(
              `이슈가 있는 라이선스 발견: ${cells[1] || "Unknown"} (isIssued: ${isIssued})`
            )
            return true
          }
        }
      }
    }

    console.log("라이선스 테이블 분석 완료: 이슈가 있는 라이선스 없음")
    return false
  } catch (error) {
    console.error("라이선스 테이블 파싱 오류:", error)
    // 파싱 실패 시 안전을 위해 true 반환 (수동 확인 필요)
    return true
  }
}

/**
 * OLIVE Platform scan URL 생성
 * @param {Object} fs - Node.js fs 모듈
 * @param {Object} core - @actions/core 객체
 * @returns {string|null} OLIVE Platform scan URL 또는 null
 */
async function generateOliveScanUrl(fs, core) {
  let oliveScanUrl = null

  try {
    console.log("🔍 OLIVE Platform scan URL 생성 시작...")
    const host = core.getInput("host") || "https://olive.kakao.com"

    if (!host) {
      console.log("❌ host 정보가 없어 URL을 생성할 수 없음")
      return null
    }

    const configPath = findConfigFile(fs)
    if (!configPath) {
      console.log("❌ local-config.yaml 파일을 찾을 수 없음")
      return null
    }

    oliveScanUrl = extractScanUrlFromConfig(fs, configPath, host)
  } catch (error) {
    console.error("OLIVE Platform scan URL 생성 오류:", error)
  }

  return oliveScanUrl
}

/**
 * local-config 파일 경로 찾기
 * @param {Object} fs - Node.js fs 모듈
 * @returns {string|null} 파일 경로 또는 null
 */
function findConfigFile(fs) {
  const artifactPath = "local-config.yaml"
  console.log(`🔍 아티팩트에서 다운로드한 local-config.yaml 파일 확인: ${artifactPath}`)

  if (fs.existsSync(artifactPath)) {
    console.log("✅ 아티팩트에서 local-config.yaml 파일 발견")
    return artifactPath
  }

  const localConfigPath = ".olive/local-config.yaml"
  console.log(`🔍 대체 경로 확인: ${localConfigPath}`)

  if (fs.existsSync(localConfigPath)) {
    console.log("✅ 대체 경로에서 local-config.yaml 파일 발견")
    return localConfigPath
  }

  return null
}

/**
 * local-config 파일에서 URL 정보 추출
 * @param {Object} fs - Node.js fs 모듈
 * @param {string} configPath - 설정 파일 경로
 * @param {string} host - OLIVE Platform 호스트 URL
 * @returns {string|null} OLIVE Platform scan URL 또는 null
 */
function extractScanUrlFromConfig(fs, configPath, host) {
  const logConfig = fs.readFileSync(configPath, "utf8")
  console.log("📄 local-config.yaml 파일 내용 일부:", logConfig.substring(0, 200) + "...")

  const projectHashMatch = logConfig.match(/projectHash:\s*"([^"]+)"/)
  const scanHashMatch = logConfig.match(/scanInfo:[\s\S]*?hash:\s*"([^"]+)"/)

  console.log("🔍 projectHash 정규식 매칭 결과:", projectHashMatch ? "매칭됨" : "매칭 안됨")
  console.log("🔍 scanHash 정규식 매칭 결과:", scanHashMatch ? "매칭됨" : "매칭 안됨")

  if (projectHashMatch && projectHashMatch[1] && scanHashMatch && scanHashMatch[1]) {
    const projectHash = projectHashMatch[1]
    const scanHash = scanHashMatch[1]

    console.log("📊 추출된 projectHash:", projectHash)
    console.log("📊 추출된 scanHash:", scanHash)

    const url = `${host}/project/detail/summary?p=${projectHash}&r=${scanHash}`
    console.log("🔗 OLIVE Platform scan 결과 URL 생성:", url)
    return url
  }

  return null
}

/**
 * PR 코멘트 본문 생성
 * @param {Object} data - 코멘트에 포함할 데이터
 * @returns {string} 코멘트 본문
 */
function generateCommentBody(data) {
  let licenseWarning = ""
  if (data.hasLicenses) {
    licenseWarning = data.hasLicenseIssue
      ? "\n\n⚠️ **주의**: 이슈가 있는 라이선스가 발견되었습니다. 의무사항 확인해서 준수 해주세요."
      : "\n\n✅ 전부 허용적인 라이선스로 고지 의무만 발생합니다."
  }

  const oliveScanLink = data.oliveScanUrl
    ? `- 🔗 OLIVE Platform 분석결과: [OLIVE Platform scan 결과 자세히보기](${data.oliveScanUrl})\n`
    : ""

  return (
    "## 🛡️ OLIVE Action\n\n" +
    "- 📦 OLIVE CLI 버전: `" +
    data.oliveCliVersion +
    "`\n" +
    "- 🎯 프로젝트 이름: `" +
    data.projectName +
    "`\n" +
    "- 🔗 상세 로그: [OLIVE Action 실행 결과](" +
    data.runUrl +
    ")\n" +
    oliveScanLink +
    "\n" +
    "### 📝 라이선스 정보\n" +
    licenseWarning +
    "\n```\n" +
    data.licenseInfo +
    "\n```\n\n" +
    "### 📊 컴포넌트 매핑 정보\n" +
    "```\n" +
    data.mappingComponentsInfo +
    "\n```\n\n" +
    "### 📊 확인이 필요한 의존성 정보\n" +
    "```\n" +
    data.unmappingDependenciesInfo +
    "\n```\n\n"
  )
}

/**
 * PR에 코멘트 생성 또는 업데이트
 * @param {Object} github - @actions/github 객체
 * @param {Object} context - GitHub 컨텍스트
 * @param {string} commentBody - 코멘트 본문
 */
async function createOrUpdateComment(github, context, commentBody) {
  const comments = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
  })

  const existingComment = comments.data.find(
    (comment) => comment.body && comment.body.includes("🛡️ OLIVE Action")
  )

  if (existingComment) {
    console.log("기존 코멘트 발견 (ID: " + existingComment.id + "). 업데이트 중...")
    await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: existingComment.id,
      body: commentBody,
    })
    console.log("✅ 기존 코멘트를 성공적으로 업데이트했습니다.")
  } else {
    console.log("기존 코멘트가 없습니다. 새 코멘트를 생성합니다.")
    await github.rest.issues.createComment({
      issue_number: context.issue.number,
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: commentBody,
    })
    console.log("✅ 새 코멘트를 성공적으로 생성했습니다.")
  }
}
