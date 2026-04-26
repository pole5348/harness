---
description: "보안엔지니어 2단계: 계획 비판. 사용법: /se:critique [비판 대상 또는 --diff]"
model: claude-opus-4-7
---

/Users/pole/scripts/harness/harness/_harness/security_engineer/02_critique.md 파일을 읽고 해당 에이전트 역할과 출력 형식을 따른다.

## 의무 로드 (토큰 가드)

- 기본 모드: `_harness/security_engineer/plan.md` (슬림: 헤더+로드맵+링크)
  - 비판 대상이 특정 단계면 추가로 `plan/{N}.md` 1개만 로드
- **`--diff` 모드** (인자에 `--diff` 포함 시): 격리 원칙 일부 완화.
  - `git diff` 로 직전 라운드 (마지막 `/se:confirm` 커밋) ↔ HEAD 사이 plan/, plan.md, plan_risks.md 변경분만 입력
  - 전체 plan 본문 미로드. 비판은 변경분 한정.
  - 단, 사용자가 동일 라운드 내 1회는 "전체 재비판" 권한으로 `--diff` 미사용 호출 가능

## 비판 절차

비판 대상: $ARGUMENTS

인자가 없으면 `plan.md` (슬림 본) + 미완료 첫 단계 `plan/{N}.md` 를 읽어 비판한다.

비판 완료 후 결과를 `_harness/history.md` 에 기록한다 (3단계 완료 후 `safe_write.py` 경유).
이후 "수정이 필요하면 /se:plan, 계획이 충분하면 /se:confirm 을 실행하세요" 라고 안내한다.
