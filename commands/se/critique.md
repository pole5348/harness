---
description: "보안엔지니어 2단계: 계획 비판. 사용법: /se:critique [계획 내용 또는 생략 시 plan.md 자동 참조]"
model: claude-opus-4-7
---

/Users/pole/scripts/harness/harness/_harness/security_engineer/02_critique.md 파일을 읽고 해당 에이전트 역할과 출력 형식을 따른다.

비판 대상: $ARGUMENTS
인자가 없으면 /Users/pole/scripts/harness/harness/_harness/security_engineer/plan.md 를 읽어 비판한다.

비판 완료 후 결과를 /Users/pole/scripts/harness/harness/_harness/history.md 에 기록한다.
이후 "수정이 필요하면 /se:plan, 계획이 충분하면 /se:confirm 을 실행하세요" 라고 안내한다.
