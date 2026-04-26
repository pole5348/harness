---
description: "보안엔지니어 계획 확정: 최종 plan.md 저장. 사용법: /se:confirm"
model: claude-sonnet-4-6
---

아래 절차를 순서대로 수행한다. 모든 산출물 경로는 **현재 작업 디렉토리(CWD) 기준**이며, `./_harness/` 디렉토리가 없으면 자동 생성한다.

1. 현재 대화의 최종 계획 내용을 확인한다. 없으면 사용자에게 계획 내용 입력을 요청한다.
2. 반드시 "감수해야 할 리스크" 섹션을 포함하여 `./_harness/security_engineer/plan.md` 를 생성(덮어쓰기)한다.
3. `./_harness/history.md` 에 "계획 확정" 이벤트를 기록한다.
4. "계획이 확정되었습니다. /se:execute 로 실행을 시작하세요" 라고 안내한다.

$ARGUMENTS
