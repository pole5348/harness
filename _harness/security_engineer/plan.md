# 프로젝트 계획: ECC 통합 v5 (최종 확정)

> 확정일: 2026-04-26
> 브랜치: `ecc-integration`
> 비판 라운드 4회 (v3 3차 + v4 토큰 비용 비판) + 사용자 답변 모두 반영.
> **v5 구조 변경**: plan.md 슬라이싱(헤더+로드맵+링크), 리스크 표 별도(`plan_risks.md`), 단계 본문은 `plan/{N}.md`.

---

## 개요

- **목표**: `everything-claude-code`의 검증된 기능 중 하네스에 부재한 핵심 요소를, 신뢰 루트와 단일 마스킹 진입점을 갖춘 안전한 단계별 구조로 통합한다. **토큰 비용을 의식한 슬라이싱·diff·skip 메커니즘 동시 도입**.
- **범위**:
  - 환경 정리: `obsidian` 브랜치 삭제, `python3` 단일 경로(`/usr/bin/python3`), GPG 미도입(시작은 chmod 600)
  - 훅 보안: `manifest_root.sha256` 신뢰 루트 + 모든 훅 self-check + SessionStart 우선 + pre-commit 자동 갱신
  - 시크릿 처리: 단일 마스킹 함수(`safe_write.py`) + `.env` 프로젝트별 + 동적 패턴 등록 + pre-commit 후처리 검증
  - 신규 커맨드: `/se:backup`(skip 로직 포함), `/se:summary`(수동), `/se:learn <model>`, `/se:learn rollback|audit|cleanup`, `/se:note <type>`
  - history 다중 세션 분리 + **결정론 스크립트(LLM 미호출) 통합**
  - status.md (메타데이터만 + 이슈 제목 마스킹)
  - Stop 훅 (메타데이터만, LLM 호출 없음)
  - PreToolUse Bash 위험도: L4는 명령에서 추출한 의미 토큰 + 5초 카운트다운
  - rules/common/security.md (점진적 1개 우선)
  - 단일 reviewer 서브에이전트 (자연어 인젝션 휴리스틱 제거)
  - Continuous Learning: 화이트리스트 yaml + `/se:note` 4타입 + decisions_index.md + 30일 만료 + **cautions.md는 audit 시에만 로드**
  - **review_report 압축 요약 + archive 정책** (Haiku 50줄 미만, 원본 archive)
  - **`/se:critique --diff` 옵션** (직전 라운드 변경분만 입력 — 격리 원칙 일부 완화)
- **제외 범위 (v5에서도 미도입)**:
  - 자연어 프롬프트 인젝션 검사 (PM-1)
  - 위협 모델 정식 작성
  - `rules/` 변조 감지
  - 토큰 베이스라인 측정 / ROI 정량 평가 (4주 후 정성 평가만)
  - 위험 Bash 차단 카테고리 (모든 등급 경고+승인)
  - GPG signed commit (운영 안정화 후 재검토)
  - 위험 Bash L1~L3 매번 다른 표현 출력
- **성공 기준**:
  - `/se:backup` 실행 시 변경 없으면 즉시 skip, 변경 있을 때만 status.md 갱신
  - 모든 history/status 쓰기가 `safe_write.py` 통과 (pre-commit 강제)
  - `manifest_root.sha256` ↔ `manifest.sha256` ↔ 훅 파일 3단계 검증 동작
  - L4 명령은 의미 토큰 입력 + 5초 카운트다운 후에만 진행
  - Continuous Learning 자동 반영은 화이트리스트 카테고리만, CLAUDE.md/rules/agents/skills/hooks/commands는 절대 자동 반영 안 됨
  - `/se:note <type>` 마킹 시 외부 입력 출처 자동 첨부, 외부 출처면 quarantine 단계 추가
  - `.env`가 프로젝트별로 `_harness/projects/{프로젝트명}/.env`에 위치하고 `.gitignore`로 강제 제외
  - 안정화 디폴트: 훅 단위 테스트 통과 + 7일 운영 무사고
  - **토큰 비용 가드**: 단계 진입 시 의무 로드 파일 1~2개로 제한, plan.md 본문은 plan/{N}.md만 로드

---

## 기술 스택

- `/usr/bin/python3` (Python 3.9.6, macOS 시스템 고정)
- Bash (검증·통합 결정론 스크립트)
- Claude Code 훅: `UserPromptSubmit`, `Stop`, `PreToolUse`, `SessionStart`
- Claude Code subagent (frontmatter `model`, `tools`)
- `hashlib`, `fcntl.flock`, `json`, `re` (stdlib)
- yaml — `pyyaml` (외부, 9단계에서만 도입)
- Git pre-commit hook
- macOS arm64/Intel 양쪽 호환

---

## 로드맵 진행률

| 단계 | 상태 | 본문 | 완료일 |
|---|---|---|---|
| 1단계: 환경 정리 + 단일 python3 + GPG 미도입 결정 | [x] | [plan/01.md](plan/01.md) | 2026-04-25 |
| 2단계: 훅 보안 신뢰 루트 (manifest_root + self-check + 자동 갱신) | [ ] | [plan/02.md](plan/02.md) | - |
| 3단계: 시크릿 마스킹 단일 진입점 + history 분리 + 결정론 통합 | [ ] | [plan/03.md](plan/03.md) | - |
| 4단계: `/se:backup` + status.md 메타데이터 + skip 로직 | [ ] | [plan/04.md](plan/04.md) | - |
| 5단계: Stop 훅 메타데이터 + `/se:summary` 수동 전용 | [ ] | [plan/05.md](plan/05.md) | - |
| 6단계: PreToolUse Bash L4 의미토큰 + 카운트다운 | [ ] | [plan/06.md](plan/06.md) | - |
| 7단계: `rules/common/security.md` 점진적 작성 | [ ] | [plan/07.md](plan/07.md) | - |
| 8단계: 단일 reviewer 서브에이전트 (자연어 인젝션 제거) | [ ] | [plan/08.md](plan/08.md) | - |
| 9단계: Continuous Learning + `/se:note` + audit 시에만 cautions 로드 | [ ] | [plan/09.md](plan/09.md) | - |
| 10단계: 통합 검증 + 문서화 + main 머지 준비 | [ ] | [plan/10.md](plan/10.md) | - |

---

## v5 신규 토큰 비용 가드 (전 단계 적용)

| 항목 | 적용 |
|---|---|
| **plan.md 슬라이싱** | 본 파일은 헤더+로드맵+링크만. 단계 본문은 `plan/{N}.md` |
| **리스크 분리** | 모든 리스크 표는 [plan_risks.md](plan_risks.md) — review/doc 단계에서만 로드 |
| **단계별 의무 로드 축소** | execute는 `plan/{현재단계}.md`만. permissions·execute_library는 변경 시점·필요 시점에만 |
| **`/se:critique --diff`** | 옵션 사용 시 직전 라운드 변경분 diff만 입력 (격리 원칙 일부 완화 — 사용자 명시 트리거) |
| **`/se:backup` skip** | 변경 없으면 skip. mtime 결정론 비교 |
| **history 결정론 통합** | `scripts/merge_history.py`로 LLM 호출 없이 단순 concat + 시간순 정렬 |
| **review_report 압축** | 단계 종료 시 Haiku로 50줄 미만 압축, 원본은 `archive/{YYYYMM}/`로 이동 |
| **cautions.md 분리** | CLAUDE.md 자동 포함 ❌ → `/se:learn audit` 호출 시에만 로드. 30일 후 archive |

---

## 단계별 의무 로드 파일 표

> **execute 단계 진입 시 매번 로드되는 파일**. 그 외는 변경/필요 시점에만.

| 단계 | 의무 로드 (1~2개) | 조건부 로드 |
|---|---|---|
| `/se:plan` | `01_plan.md`, (이전) `plan.md` | 신규 계획 시 빈 컨텍스트 |
| `/se:critique` | `02_critique.md`, `plan.md` (또는 `--diff` 모드 시 직전 라운드 diff) | 없음 |
| `/se:confirm` | `commands/se/confirm.md` 자체 절차 | 없음 |
| `/se:execute N` | `03_execute.md`, `plan/{N}.md` | execute_library.md (외부 라이브러리 사용 시), permissions.md (권한 변경 시) |
| `/se:review` | `04_review.md`, 해당 단계 산출물, `plan_risks.md` | sbom_report.md, archive (필요 시) |
| `/se:doc` | `05_document.md`, `review_report.md`, `plan.md`, `plan_risks.md` | 없음 |
| `/se:backup` | `commands/se/backup.md` 절차 (LLM 최소화) | 없음 (skip 시 즉시 종료) |
| `/se:summary` | `commands/se/summary.md` + 트랜스크립트 | 없음 |
| `/se:note <type>` | `commands/se/note.md` + 직전 10분 메타데이터 | quarantine 디렉토리 (외부 출처 발견 시) |
| `/se:learn audit` | `commands/se/learn-audit.md`, `cautions.md`, `decisions_index.md` | 없음 |
| `/se:learn cleanup` | `commands/se/learn-cleanup.md` | quarantine, cautions, archive 디렉토리 |

---

## 참고 산출물 인덱스

| 항목 | 위치 |
|---|---|
| 단계별 본문 | `plan/{01..10}.md` |
| 리스크 표 (분리) | [plan_risks.md](plan_risks.md) |
| 비판 라운드 이력 | `_harness/history.md` |
| 권한·정책 | `_harness/permissions.md` |
| 실행 단계 라이브러리 | `_harness/security_engineer/execute_library.md` |
| 검토 리포트 (단계별) | `_harness/security_engineer/review_report.md` (최신 1개 + diff 로그) |
| 검토 리포트 archive | `_harness/security_engineer/archive/{YYYYMM}/review_*.md` |
| 프로젝트별 .env | `_harness/projects/{프로젝트명}/.env` |
| 시크릿 마스킹 함수 | `hooks/lib/safe_write.py` |
| 매니페스트 신뢰 루트 | `~/.claude/manifest_root.sha256` |
| Continuous Learning | `_harness/continuous_learning/` (whitelist.yaml, decisions_index.md, quarantine/, archive/) |
