---
description: "보안엔지니어 자율 실행 루프. 사용법: /harness:auto [시작단계 N | 단계 범위 N..M | 생략=첫 미완료부터]"
model: claude-sonnet-4-6
---

~/.claude/_harness/security_engineer/03_execute.md (실행 에이전트 정의) + ~/.claude/rules/common/karpathy_guidelines.md (Karpathy 4원칙) 을 함께 로드한다.

> **목적**: `/harness:execute` 를 단계마다 수동 호출하는 대신, **`Verification` 통과까지 자율 루프** 로 다음 단계로 자동 진행. jha0313/harness_framework 의 `execute.py` 영감.

실행 인자: $ARGUMENTS  (예: `1`, `1..5`, `--all`, 생략)

## 실행 알고리즘

```
1. plan.md 로드맵 파싱 → 시작 단계 N 결정
   - 인자 N: N단계부터
   - 인자 N..M: N~M 단계
   - 인자 --all 또는 생략: 첫 미완료 단계부터 끝까지
2. for each step in [N..end]:
   a) plan/{step}.md 로드
   b) Assumptions 표 — "확인 필요" 항목 모두 확정 상태인지 검증
      - 미확정 발견 시: 사용자에게 확정 요청 후 STOP (자율 루프 중단)
   c) 성공 기준 (Verification) 섹션 존재 여부 확인
      - 없으면: 사용자에게 보강 요청 후 STOP
   d) 단계 실행 (Karpathy 4원칙 의무 적용)
      - 1원칙: 모호하면 사용자에게 질문 후 STOP
      - 2원칙: 추상화/유연성 추가 금지
      - 3원칙: 변경 범위는 plan/{N}.md 에 명시된 파일만
   e) 검증 명령 실행 (`Verification` 의 `검증 명령`)
      - 통과 → step 완료 처리, plan.md 로드맵 [x] 갱신, history.md 기록, 다음 step
      - 실패 → 자동 수정 시도 (최대 3회):
          * 실패 사유 분석
          * surgical 수정 (3원칙 유지)
          * 재실행
      - 3회 모두 실패 → step 을 "blocked" 표시, history.md 에 실패 사유 기록, STOP
3. 모든 step 완료 시 사용자에게 "/harness:review 로 종합 검토를 진행하세요" 안내
```

## 의무 로드 (토큰 가드)

- `./_harness/security_engineer/plan.md` (헤더+로드맵만)
- `~/.claude/_harness/security_engineer/03_execute.md`
- `~/.claude/rules/common/karpathy_guidelines.md`
- 진입할 단계의 `./_harness/security_engineer/plan/{N}.md` (한 번에 1개씩 — 다음 단계 진입 시 로드)

## STOP 조건 (사용자 개입 필요)

다음 중 어느 하나라도 발생하면 자율 루프를 즉시 중단하고 사용자에게 보고한다:

1. **Assumption 미확정**: `plan/{N}.md` 의 `Assumptions` 표에 "확인 필요" 항목이 남아있음 (Karpathy 1원칙)
2. **Verification 섹션 누락**: 단계에 검증 기준이 정의되지 않음 (Karpathy 4원칙)
3. **3회 실패**: 동일 단계 검증이 3회 연속 실패 → `blocked` 표시
4. **모호한 지시**: plan/{N}.md 에 다중 해석 가능한 항목 발견 (Karpathy 1원칙)
5. **외부 의존성 추가 필요**: SBOM 갱신 사항 발견 시 사용자 승인 요구
6. **bash_safety 차단**: 위험 패턴 매칭 시 — 명령 변형/분리 방안을 사용자와 협의

## 상태 추적

`./_harness/security_engineer/auto_state.json` 에 라운드별 진행 상태 기록 (없으면 생성):

```json
{
  "session_started": "2026-04-30T10:00:00",
  "steps": {
    "1": {"status": "completed", "attempts": 1, "completed_at": "..."},
    "2": {"status": "blocked", "attempts": 3, "last_error": "..."},
    "3": {"status": "pending"}
  }
}
```

## 보고 형식

세션 종료 시 (정상/STOP) 다음 요약을 사용자에게 출력:

```
[/harness:auto 결과]
- 완료: 단계 1, 2 (2/N)
- 실패: 단계 3 — blocked (3회 실패: <마지막 사유>)
- 미실행: 단계 4, 5
- 다음 행동: <STOP 사유에 따른 권장 명령>
```

## 비교: `/harness:execute` 와 차이

| 항목 | `/harness:execute N` | `/harness:auto [범위]` |
|---|---|---|
| 호출 단위 | 단일 단계 | 복수 단계 자율 루프 |
| 검증 실패 시 | 사용자 호출 대기 | 최대 3회 자동 수정 시도 |
| 단계 진입 | 사용자가 다음 단계 호출 | 통과 시 자동 다음 단계 |
| 토큰 비용 | 단계당 매번 컨텍스트 재설정 | 단일 세션에서 캐시 재활용 (절감) |
| 위험 | 적음 | 변경 범위 큼 — Surgical 원칙 더 엄격하게 준수 |

> **권장 사용**: 첫 단계는 `/harness:execute 1` 로 수동 검증 후, 2단계부터 `/harness:auto 2..` 로 자율 진행.
