---
description: "보안엔지니어 3단계: 계획 기반 실행. 사용법: /harness:execute [단계번호 또는 태스크명]"
model: claude-sonnet-4-6
---

~/.claude/_harness/security_engineer/03_execute.md (글로벌 정의 파일) 을 읽고 해당 에이전트 역할과 규칙을 따른다.

> **경로 규약**: 정의/라이브러리 파일은 글로벌 절대경로(`~/.claude/_harness/...`), 산출물(`plan.md`, `plan/`, `history.md`, `sbom_report.md` 등)은 **CWD 기준 `./_harness/...`**.

## 의무 로드 (토큰 가드)

1. `./_harness/security_engineer/plan.md` — 헤더+로드맵만 (단계 본문은 미포함)
2. 인자에 따라 결정:
   - 단계번호 N (1~10) → `./_harness/security_engineer/plan/{N}.md` 만 로드
   - 태스크명 → `plan.md` 로드맵에서 `[ ]` 미완료 단계 매칭, 해당 `./_harness/security_engineer/plan/{N}.md` 로드
   - 인자 없음 → `plan.md` 로드맵에서 첫 `[ ]` 단계 자동 선택, 해당 `./_harness/security_engineer/plan/{N}.md` 로드

**전체 plan.md 본문 또는 다른 단계 plan/*.md를 임의로 로드하지 않는다** (토큰 가드).

## 의무 로드 추가 (Karpathy 4원칙)

- `~/.claude/rules/common/karpathy_guidelines.md` — **모든 실행에서 의무 로드** (코딩 행동 지침 4원칙)

## 조건부 로드

- `~/.claude/_harness/security_engineer/execute_library.md` (글로벌 정의) — **외부 라이브러리·MCP 사용이 필요할 때만** 로드
- `~/.claude/_harness/permissions.md` (글로벌 정의) — **권한 변경이 필요할 때만** 로드
- `rules/common/security.md` — 7단계 완료 후 모든 실행에서 로드 (그 이전 단계에서는 미로드)

## 실행

실행할 태스크: $ARGUMENTS

외부 라이브러리 사용 시 `./_harness/security_engineer/sbom_report.md` 에 자동 기록한다.
태스크 완료마다 `./_harness/history.md` 를 업데이트한다 (3단계 완료 후 `safe_write.py` 경유).
단계 완료 시 `./_harness/security_engineer/plan.md` 로드맵의 해당 행을 `[x]` + 완료일자로 갱신한다.
