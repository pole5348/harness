---
description: "보안엔지니어 이력 요약 및 재개. 사용법: /harness:continue [--full | --since YYYY-MM-DD | --no-record]"
model: claude-sonnet-4-6
---

> **목적**: 현재 프로젝트(`CWD/_harness/`)의 진행 이력을 요약하고, 다음에 실행할 슬래시 커맨드를 우선순위대로 권고한다.
> 세션 재개·인수인계·진척률 점검에 사용. **읽기 전용** 동작이 기본이며, 옵션에 따라 `history.md` 에 점검 기록 1줄만 남긴다.

실행 인자: $ARGUMENTS

## 의무 로드 (토큰 가드)

> 모든 산출물 경로는 **CWD 기준 `./_harness/...`** (프로젝트 로컬).

1. `./_harness/history.md` — 인자에 따라 슬라이싱
   - 인자 없음 또는 `--recent`: 최근 20개 항목만
   - `--full`: 전체 (대용량일 경우 마지막 200줄로 자체 cap)
   - `--since YYYY-MM-DD`: 해당 날짜 이후 항목만
2. `./_harness/security_engineer/plan.md` (있으면 — 헤더+로드맵만)

## 조건부 로드

- `./_harness/security_engineer/auto_state.json` (있으면 — 단계별 상태)
- `./_harness/security_engineer/review_report.md` (있으면 — 검토 완료 여부 판정용)
- `./_harness/security_engineer/sbom_report.md` (있으면 — 외부 의존성 변동 확인용, 마지막 5줄만)
- `./_harness/security_engineer/docs/` 디렉토리 목록 (문서화 완료 여부 판정용)

## 분석 절차

1. **존재 검증 (1원칙: Think Before Coding)**
   - `./_harness/` 가 없으면 **STOP** → "이 디렉토리는 하네스 프로젝트가 아닙니다. `/harness:plan <주제>` 로 새로 시작하세요." 안내 후 종료.
   - `history.md` 가 없고 `plan.md` 도 없으면 동일 안내.

2. **history.md 요약**
   - 인자 슬라이싱 적용 후 항목별로 (시각, 단계, 결정/이슈/완료) 추출
   - 시간순 정렬 + 단계별 그룹핑
   - 마지막 활동 시각·단계 식별

3. **plan.md 진척률 산출**
   - 로드맵 표 파싱 → `[x]` (완료) / `[ ]` (미완료) 카운트
   - 각 단계의 완료일자(있으면) 표기

4. **auto_state.json 분석** (있을 때만)
   - `completed` / `blocked` / `pending` 단계 목록 추출
   - blocked 사유(`last_error`) 요약 (한 줄)

5. **다음 행동 권고 — 우선순위 규칙**
   다음 순서로 첫 매칭 조건의 권고를 1순위로 출력하고, 적절한 대안 1~2개를 제시한다:

   | 우선순위 | 조건 | 1순위 권고 |
   |---|---|---|
   | 1 | `plan.md` 자체가 없음 | `/harness:plan <주제>` |
   | 2 | `plan.md` 는 있으나 비판 루프 중 (history 마지막 이벤트가 critique) | `/harness:critique --diff` 또는 `/harness:confirm` |
   | 3 | `auto_state.json` 에 `blocked` 단계 존재 | `/harness:execute {N}` (수동 재시도) — blocked 사유 함께 보고 |
   | 4 | 미완료(`[ ]`) 단계 존재 + `auto_state` 에 blocked 없음 | 첫 미완료 단계 N → `/harness:execute {N}` 또는 `/harness:auto {N}..` |
   | 5 | 모든 단계 완료 + `review_report.md` 없음 | `/harness:review` |
   | 6 | `review_report.md` 있음 + `docs/` 비어있거나 부족 | `/harness:doc PRD` / `ADR` / `ARCH` / `UI` 중 컨텍스트에 맞는 것 |
   | 7 | 모든 산출물 완료 | "이 프로젝트는 완료 상태입니다. 새 주제는 `/harness:plan <주제>` 로 시작하세요." |

6. **(옵션) 점검 기록**
   - `--no-record` 인자가 **없으면** `./_harness/history.md` 에 다음 한 줄 추가:
     ```
     ## YYYY-MM-DD HH:MM — 이력 점검 (continue)
     - 진척률: {x}/{y}, blocked: {N개}, 다음 권고: /harness:{cmd}
     ```
   - `--no-record` 인자가 **있으면** 어떤 파일도 수정하지 않는다 (완전 읽기 전용).

## 출력 형식

```
[/harness:continue 결과] 2026-04-30 14:32

## 진행 요약
- 프로젝트: <plan.md 헤더에서 추출한 프로젝트명>
- 마지막 활동: 2026-04-29 18:11 — <마지막 history 항목 한 줄>
- 진척률: 3/7 단계 완료 (43%)
- 외부 의존성: <sbom 마지막 5줄 요약 또는 "없음">

## 단계별 상태
| 단계 | 이름 | 상태 | 비고 |
|---|---|---|---|
| 1 | 토큰 파서 구현 | ✅ completed | 2026-04-27 |
| 2 | 서명 검증 | ✅ completed | 2026-04-28 |
| 3 | exp/nbf 처리 | ✅ completed | 2026-04-29 |
| 4 | 키 로테이션 | ⛔ blocked | auto 3회 실패: pytest tests/test_rotation.py |
| 5 | 통합 테스트 | ⏸ pending | - |

## 최근 결정·이슈 (최근 N개)
- 2026-04-29 18:11: HS256 채택 결정 (ADR-2 작성)
- 2026-04-29 16:40: 4단계 검증 실패 — exp 클레임 처리 버그
- 2026-04-28 09:12: SBOM 갱신 — pyjwt 2.8.0 추가

## 다음 권장 행동
**1순위**: `/harness:execute 4`
   - 사유: auto 가 3회 실패 후 STOP. 사용자 수동 검증 필요.
   - 마지막 에러: <auto_state.last_error 한 줄 요약>
   - 검증 명령: `pytest tests/test_rotation.py -v`

**대안**:
- `/harness:critique 4` — 4단계 plan 자체에 문제가 있는지 재점검
- `/teacher:ask JWT 키 로테이션 베스트 프랙티스` — 개념 확인 후 재진입

## 점검 기록
- ✅ ./_harness/history.md 에 점검 기록 1줄 추가 (또는 "--no-record 로 미기록")
```

## STOP 조건 (사용자 개입 필요)

1. **하네스 프로젝트 아님**: `./_harness/` 디렉토리가 없거나 `plan.md`/`history.md` 모두 부재 → 시작 안내 후 종료.
2. **history.md 손상**: 파싱 불가능한 형식 (헤더 없음 등) → 사용자에게 수동 확인 요청.
3. **로드맵 표 형식 불일치**: `plan.md` 가 v5.x 슬림 포맷이 아님 → 사용자에게 `/harness:confirm` 재실행 권유.

## 비교: 다른 운영 커맨드와 차이

| 항목 | `/harness:continue` | `/harness:review` | `/harness:auto` |
|---|---|---|---|
| 호출 시점 | 세션 재개 시 (작업 시작 전) | 모든 단계 완료 후 | 작업 진행 중 |
| 동작 | 이력 요약 + 다음 행동 권고 | 종합 검토 보고서 작성 | 자율 실행 루프 |
| 산출물 | (없음 또는 history 1줄) | `review_report.md` | 단계별 산출물 + auto_state.json |
| 모델 비용 | Sonnet — 빠른 요약 | Sonnet — 정밀 검토 | Sonnet — 실행 |
| 토큰 비용 | 매우 낮음 (history 슬라이싱) | 중간 | 누적 큼 |

> **권장 사용**: 새 세션을 시작할 때 가장 먼저 호출. `/harness:continue` → 권고된 명령 → 작업 진행.
