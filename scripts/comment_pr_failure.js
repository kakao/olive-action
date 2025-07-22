module.exports = async ({ github, context, core }) => {
  /**
   * GitHub Actions에서 입력값 가져오기
   * @param {Object} core - @actions/core 객체
   * @returns {Object} 입력값 객체
   */
  function getInputData(core) {
    return {
      projectName: core.getInput("project-name"),
      runUrl:
        process.env.GITHUB_SERVER_URL +
        "/" +
        process.env.GITHUB_REPOSITORY +
        "/actions/runs/" +
        process.env.GITHUB_RUN_ID,
    }
  }

  /**
   * 실패 PR 코멘트 본문 생성
   * @param {Object} data - 코멘트에 포함할 데이터
   * @returns {string} 코멘트 본문
   */
  function generateFailureCommentBody(data) {
    return (
      "## 🛡️ OLIVE CLI 스캔\n\n" +
      "- 🎯 프로젝트 이름: `" +
      data.projectName +
      "`\n" +
      "- 🔗 상세 로그: [GitHub Actions 실행 결과](" +
      data.runUrl +
      ")\n\n" +
      "❌ **OLIVE CLI 스캔이 실패했습니다. 상세 로그에서 확인하실 수 있습니다.**\n\n"
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
      (comment) => comment.body && comment.body.includes("🛡️ OLIVE CLI 스캔")
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

  const inputData = getInputData(core)
  const commentBody = generateFailureCommentBody(inputData)
  await createOrUpdateComment(github, context, commentBody)
}
