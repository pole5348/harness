---
description: "보안엔지니어 3단계: 계획 기반 실행. 사용법: /se:execute [태스크명 또는 단계번호]"
model: claude-sonnet-4-6
---

/Users/pole/scripts/harness/harness/_harness/security_engineer/03_execute.md 파일을 읽고 해당 에이전트 역할과 규칙을 따른다.
실행 라이브러리: /Users/pole/scripts/harness/harness/_harness/security_engineer/execute_library.md

실행할 태스크: $ARGUMENTS
인자가 없으면 plan.md 의 다음 미완료 태스크를 찾아 실행한다.

외부 라이브러리 사용 시 /Users/pole/scripts/harness/harness/_harness/security_engineer/sbom_report.md 에 자동 기록한다.
태스크 완료마다 /Users/pole/scripts/harness/harness/_harness/history.md 를 업데이트한다.
