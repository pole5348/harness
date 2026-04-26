# Harness Engineering

> Claude Code 하네스 엔지니어링 기반의 프롬프트 관리 레포입니다.
> CLAUDE.md 변경 이력을 Git으로 추적하고, 페르소나별 에이전트 워크플로를 정의합니다.
> 토큰 비용을 의식한 슬라이싱·diff·skip 메커니즘을 v5에서 도입했습니다.

---

## 1. 디렉토리 구조 (최종 v5)

> **경로 규약 (v5.1 — 정의/산출물 분리)**:
> - **정의 파일**(에이전트 시스템 프롬프트, `permissions.md`, `execute_library.md`)은 글로벌 위치 `/Users/pole/scripts/harness/harness/_harness/` 에 보관하고 **절대경로**로 참조한다.
> - **산출물**(`history.md`, `plan.md`, `plan/`, `plan_risks.md`, `sbom_report.md`, `review_report.md`, `docs/` 등)은 **현재 작업 디렉토리(CWD) 기준 `./_harness/`** 에 저장된다 — 즉 프로젝트마다 `_harness/`가 따로 생긴다. 디렉토리가 없으면 자동 생성.
> - 여러 프로젝트의 산출물을 한 곳에서 보고 싶을 때는 `/se:doc --central` (또는 학부생 `/teacher:doc` 중앙화 옵션)으로 글로벌 `_harness/{persona}/docs/central/` 에 수합한다.

### 글로벌 레포 (이 레포 = 정의·훅·커맨드)

```
harness/
├── CLAUDE.md                           # 글로벌 지침 (↔ ~/.claude/CLAUDE.md 심볼릭 링크)
├── README.md                           # 본 문서
├── .env.example                        # 시크릿 슬롯 템플릿 (Git 추적)
├── .gitignore                          # 시크릿/격리/임시 파일 제외 규칙
├── hooks/                              # 훅 스크립트 (↔ ~/.claude/hooks/ 심볼릭)
│   ├── model_switch.py                 # UserPromptSubmit — 커맨드별 모델 전환
│   ├── session_start.py                # SessionStart — 매니페스트 검증 (2단계)
│   ├── session_stop.py                 # Stop — 메타데이터 기록 (5단계)
│   ├── bash_safety.py                  # PreToolUse Bash — L1~L4 위험도 (6단계)
│   ├── manifest.sha256                 # 훅 파일 SHA256 (2단계)
│   └── lib/
│       ├── safe_write.py               # history/status 단일 마스킹 진입점 (3단계)
│       ├── secret_patterns.json        # 정적 시크릿 패턴 (3단계)
│       └── bash_patterns.json          # Bash 위험 패턴 (6단계)
├── commands/                           # 슬래시 커맨드 (↔ ~/.claude/commands/ 심볼릭)
│   ├── se/                             # 보안 엔지니어
│   │   ├── plan.md, critique.md, confirm.md, execute.md, review.md, doc.md
│   │   ├── backup.md                   # /se:backup (4단계)
│   │   ├── summary.md                  # /se:summary (5단계)
│   │   ├── note.md                     # /se:note (9단계)
│   │   └── learn.md, learn-rollback.md, learn-audit.md, learn-cleanup.md  # (9단계)
│   └── teacher/                        # 학부생
│       ├── ask.md
│       └── doc.md
├── agents/                             # 서브에이전트 정의 (↔ ~/.claude/agents/ 심볼릭)
│   └── code-security-reviewer.md       # (8단계)
├── rules/                              # 보안 코딩 규칙 (7단계)
│   └── common/security.md
├── skills/                             # 스킬 정의 (9단계)
│   └── continuous_learning/extractor.md
├── scripts/                            # 결정론 유틸리티 (LLM 미호출)
│   ├── update_manifest.sh              # 매니페스트 자동 갱신 (2단계)
│   └── merge_history.py                # 분기 history 시간순 통합 (3단계)
└── _harness/                           # ★ 글로벌 정의 + 중앙화 수합 + 레거시 산출물
    ├── permissions.md                  # [정의] 단계별 권한 + 보안 정책 결정
    ├── continuous_learning/            # [정의] (9단계)
    │   ├── whitelist.yaml
    │   ├── decisions_index.md
    │   ├── cautions.md                 # CLAUDE.md 자동 포함 ❌, /se:learn audit 시에만 로드
    │   ├── WARNINGS.md
    │   ├── quarantine/                 # Git 제외
    │   └── archive/{YYYYMM}/           # 30일 만료 후 이동
    ├── projects/                       # [설정] 프로젝트별 .env (Git 제외)
    │   └── {프로젝트명}/.env
    ├── security_engineer/
    │   ├── 01_plan.md ~ 05_document.md  # [정의] 페르소나 단계별 에이전트 정의
    │   ├── execute_library.md          # [정의] 외부 라이브러리·MCP 라이브러리
    │   └── docs/central/               # [수합] /se:doc --central 중앙화 산출물
    └── student/
        ├── 01_ask.md, 02_document.md   # [정의] 페르소나 에이전트
        └── docs/central/               # [수합] /teacher:doc 중앙화 학습 노트
```

### 프로젝트 로컬 (각 프로젝트의 작업 디렉토리)

```
<프로젝트 루트>/                          # = 슬래시 커맨드를 실행한 CWD
└── _harness/                           # 산출물 — 자동 생성
    ├── history.md                      # 이 프로젝트의 진행 이력
    ├── history_*.md                    # 다중 세션 분기 (Git 제외, 통합 후 정리)
    ├── status.md                       # /se:backup 스냅샷 (4단계)
    ├── integrity_alert.md              # 매니페스트 불일치 알림 (2단계)
    ├── security_engineer/
    │   ├── plan.md                     # ★ 슬림 — 헤더+로드맵+링크만
    │   ├── plan_risks.md               # ★ 리스크 표 분리 (review/doc 시에만 로드)
    │   ├── plan/01.md ~ 10.md          # ★ 단계별 본문 (execute가 자기 단계만 로드)
    │   ├── sbom_report.md              # 외부 라이브러리 사용 시 자동 기록
    │   ├── review_report.md            # 최신 1개 + diff 로그 (압축 요약 50줄 미만)
    │   ├── archive/{YYYYMM}/           # review_report 원본 보관
    │   └── docs/                       # /se:doc 산출물 (이 프로젝트 한정)
    └── student/
        └── docs/                       # /teacher:doc 학습 노트 (이 프로젝트 한정)
```

> **레거시 노트**: 2026-04-26 이전에 글로벌 `_harness/` 안에 누적된 산출물(`history.md`, `plan.md`, `plan/`, `plan_risks.md`, `review_report.md`)은 그대로 두고, 새 프로젝트부터 위 분리 규칙을 적용한다.

---

## 2. 단계별 파일 로드·수정 매트릭스

> **토큰 가드**: 단계 진입 시 의무 로드 파일을 1~2개로 제한. 그 외는 변경/필요 시점에만.
> **경로 표기**: `./_harness/...` 는 프로젝트 로컬(CWD), 그 외(예: `permissions.md`, `01_plan.md`, `execute_library.md`, `cautions.md`, `whitelist.yaml`)는 글로벌 정의(`/Users/pole/scripts/harness/harness/_harness/...`).

| 슬래시 커맨드 | 모델 | 의무 로드 (자동) | 조건부 로드 | 자동 수정 파일 |
|---|---|---|---|---|
| `/se:plan` | Opus 4.7 | `01_plan.md`(글로벌), (이전) `./_harness/security_engineer/plan.md` | 없음 | (대화에만 — 확정 전 미저장) |
| `/se:critique` | Opus 4.7 | `02_critique.md`(글로벌), `./_harness/security_engineer/plan.md`(슬림) + 대상 `./_harness/security_engineer/plan/{N}.md` 1개 | `--diff` 모드: `git diff` 직전 라운드만 | `./_harness/history.md` (비판 이력 추가) |
| `/se:confirm` | Sonnet 4.6 | `commands/se/confirm.md` 절차 | 없음 | `./_harness/security_engineer/{plan.md, plan/{N}.md, plan_risks.md}`, `./_harness/history.md` |
| `/se:execute N` | Sonnet 4.6 | `03_execute.md`(글로벌), `./_harness/security_engineer/plan/{N}.md` 1개 | `execute_library.md`(글로벌, 외부 의존성 시), `permissions.md`(글로벌, 권한 변경 시), `rules/common/security.md`(7단계 후) | 단계 산출물, `./_harness/security_engineer/sbom_report.md`, `./_harness/history.md`, `./_harness/security_engineer/plan.md` 로드맵 체크 |
| `/se:review` | Sonnet 4.6 | `04_review.md`(글로벌), 단계 산출물, `./_harness/security_engineer/plan_risks.md` | `./_harness/security_engineer/sbom_report.md`, `./_harness/security_engineer/archive/`(필요 시) | `./_harness/security_engineer/review_report.md` (압축 요약), `./_harness/security_engineer/archive/{YYYYMM}/` (원본 이동) |
| `/se:doc [A/B/C/D]` | Haiku 4.5 | `05_document.md`(글로벌), `./_harness/security_engineer/{review_report.md, plan.md(슬림), plan_risks.md}` | 없음 | 기본 `./_harness/security_engineer/docs/` (프로젝트 로컬). `--central` 시 글로벌 `_harness/security_engineer/docs/central/` |
| `/se:backup` | Sonnet 4.6 | `commands/se/backup.md` 절차 | (변경 없으면 즉시 skip) | `./_harness/status.md` (변경 시에만), `./_harness/history.md` 통합 |
| `/se:summary` | Sonnet 4.6 | `commands/se/summary.md` + 트랜스크립트 | 없음 | `./_harness/security_engineer/docs/summary_*.md` |
| `/se:note <type>` | Sonnet 4.6 | `commands/se/note.md` + 직전 10분 메타데이터 | `quarantine/`(글로벌, 외부 출처 발견 시) | `decisions_index.md`(글로벌) 또는 `quarantine/`(글로벌) |
| `/se:learn sonnet\|opus` | 인자 따라 | `commands/se/learn.md`, `quarantine/`(글로벌) | 없음 | `quarantine/`(글로벌, 수락/거부 표시) |
| `/se:learn audit` | Sonnet 4.6 | `commands/se/learn-audit.md`, `cautions.md`(글로벌), `decisions_index.md`(글로벌) | 없음 | `cautions.md`(글로벌, 점검 결과 추가) |
| `/se:learn cleanup` | Sonnet 4.6 | `commands/se/learn-cleanup.md` | `quarantine/`(글로벌), `cautions.md`(글로벌) | `archive/{YYYYMM}/`(글로벌) 이동 |
| `/se:learn rollback <hash>` | Sonnet 4.6 | `commands/se/learn-rollback.md` + git 로그 | 없음 | git revert 커밋 |
| `/teacher:ask` | Sonnet 4.6 | `01_ask.md`(글로벌) | 없음 | (대화만) |
| `/teacher:doc` | Sonnet 4.6 | `02_document.md`(글로벌) | 없음 | 기본 `./_harness/student/docs/` (프로젝트 로컬). 중앙화 시 글로벌 `_harness/student/docs/central/` |

> **CLAUDE.md는 모든 세션에서 자동 로드**. 그 외 파일은 위 표에 명시된 경우에만 로드된다.

---

## 3. 워크플로 시나리오

### 보안 엔지니어 표준 진행

```
/se:plan 취약점 스캐너 개발          ← Opus, plan.md 슬림 + 단계 본문 작성
/se:critique                         ← Opus, plan.md + 단계 본문 비판
/se:plan 수정사항 반영                ← Opus, 재계획
/se:critique --diff                  ← Opus, 직전 라운드 변경분만 비판 (토큰 절약)
/se:confirm                          ← Sonnet, plan.md+plan/+plan_risks.md 저장
/se:execute 1                        ← Sonnet, plan/01.md만 로드 후 실행
/se:review                           ← Sonnet, 산출물+plan_risks 로드, review_report 압축
/se:doc B                            ← Haiku, 외부 보안 리포트 생성
/se:backup                           ← Sonnet, 변경 없으면 즉시 skip
```

### 학부생 Q&A (보안 작업 중 즉시 전환)

```
/teacher:ask JWT 토큰이 뭐야?        ← Sonnet
/teacher:doc 오늘 배운 JWT 내용 정리 ← Sonnet
```

### Continuous Learning (9단계 도입 후)

```
/se:note decision <내용>             ← 결론 마킹 → decisions_index.md
/se:note rationale <내용>            ← 판단 근거 마킹
/se:learn sonnet                     ← quarantine 검토·수락·거부
/se:learn audit                      ← 주간 자동 반영 점검 (cautions.md 이때만 로드)
/se:learn cleanup                    ← 30일 만료 archive 이동
/se:learn rollback <commit-hash>     ← 잘못 반영된 자동 학습 되돌리기
```

---

## 4. 모델 할당 (자동 전환 — `model_switch.py`)

| 커맨드 | 모델 | 단가 비교 |
|---|---|---|
| `/se:plan`, `/se:critique` | claude-opus-4-7 | Sonnet의 약 5배 |
| `/se:confirm`, `/se:execute`, `/se:review`, `/se:backup`, `/se:summary`, `/se:note`, `/se:learn (rollback/audit/cleanup)` | claude-sonnet-4-6 | 기준 |
| `/se:learn opus` | claude-opus-4-7 | 사용자 명시 시 |
| `/se:learn sonnet` | claude-sonnet-4-6 | 사용자 명시 시 |
| `/se:doc` | claude-haiku-4-5-20251001 | Sonnet의 약 1/4 |
| `/teacher:ask`, `/teacher:doc` | claude-sonnet-4-6 | 기준 |

> **모델 전환 시 프롬프트 캐시 무효화**. 동일 단계 내에서는 모델을 고정하고, 단계 묶음 처리(예: execute → review 같은 세션)를 권장한다.

---

## 5. 사용자가 참고해야 하는 파일

| 우선순위 | 파일 | 종류 | 언제 |
|---|---|---|---|
| ★★★ | [CLAUDE.md](CLAUDE.md) | 글로벌 정의 | 항상 (모든 세션 자동 로드) |
| ★★★ | `./_harness/security_engineer/plan.md` | 프로젝트 산출물 | 모든 단계 — 헤더+로드맵 확인 |
| ★★★ | `./_harness/security_engineer/plan/{N}.md` | 프로젝트 산출물 | 진입할 단계 본문 |
| ★★ | `./_harness/history.md` | 프로젝트 산출물 | 세션 재개 시 가장 먼저 |
| ★★ | [_harness/permissions.md](_harness/permissions.md) | 글로벌 정의 | 권한·보안 정책 변경 시 |
| ★★ | `./_harness/security_engineer/plan_risks.md` | 프로젝트 산출물 | review/doc 단계 또는 의사결정 시 |
| ★ | [_harness/security_engineer/execute_library.md](_harness/security_engineer/execute_library.md) | 글로벌 정의 | 외부 라이브러리·MCP 사용 시 |
| ★ | `./_harness/security_engineer/review_report.md` | 프로젝트 산출물 | 검토 직후 |
| ★ | [.env.example](.env.example) | 글로벌 정의 | 새 시크릿 슬롯 추가 시 |

> 프로젝트 산출물 경로(`./_harness/...`)는 슬래시 커맨드를 실행한 작업 디렉토리(CWD) 기준이라 프로젝트마다 다르다. 글로벌 정의 파일은 위 마크다운 링크가 가리키는 절대경로 `/Users/pole/scripts/harness/harness/_harness/...` 의 단일 사본이다.

---

## 6. Security Guardrails (사용자 주기적 트래킹·수정 권장)

> **다음 파일들은 보안 핵심 자산입니다.** 변경 시 반드시 git diff 검토 + history.md 기록.
> 정기 점검 주기를 권장합니다.

| 파일 | 점검 주기 | 점검 내용 | 변경 시 영향 |
|---|---|---|---|
| [_harness/permissions.md](_harness/permissions.md) | **월 1회** | 단계별 허용 도구·금지 항목, GPG 도입 시점, Python 경로 | 모든 단계의 권한 경계 |
| [.gitignore](.gitignore) | **변경 시 즉시** | `.env*` 패턴, quarantine, history 분기 | 시크릿 누출 직접 영향 |
| [.env.example](.env.example) | 새 시크릿 추가 시 | 슬롯 정의 (값 없음) | 동적 마스킹 패턴 등록 대상 |
| [hooks/model_switch.py](hooks/model_switch.py) | 신규 커맨드 추가 시 | 매핑 정확성, regex 안정성 | 모델 자동 전환 핵심 |
| [hooks/manifest.sha256](hooks/manifest.sha256) | **훅 변경 시 즉시** (자동) | SHA256 일치 여부 | 훅 변조 검증 |
| [~/.claude/manifest_root.sha256](~/.claude/manifest_root.sha256) | **훅 변경 시 즉시** (자동) | 신뢰 루트 (chmod 600) | 매니페스트 변조 검증 |
| [hooks/lib/safe_write.py](hooks/lib/safe_write.py) | 시크릿 패턴 추가 시 | 정적/동적 마스킹 적용 범위 | history/status 누출 차단 |
| [hooks/lib/secret_patterns.json](hooks/lib/secret_patterns.json) | **분기 1회** (CVE/신규 패턴 반영) | API 키 신규 형식 추가 | 마스킹 누락 방지 |
| [hooks/lib/bash_patterns.json](hooks/lib/bash_patterns.json) | **분기 1회** | L4 위험 명령 패턴 누락 여부 | 시스템 손상 방지 |
| `./_harness/security_engineer/plan_risks.md` (프로젝트 로컬) | **단계 종료 시** | 식별 리스크 vs 감수 리스크 재평가 | 리스크 가시성 |
| [_harness/continuous_learning/whitelist.yaml](_harness/continuous_learning/whitelist.yaml) | **월 1회** | auto_apply ↔ manual_only 분류 정확성 | 자동 학습 안전 경계 |
| [_harness/continuous_learning/cautions.md](_harness/continuous_learning/cautions.md) | `/se:learn audit` 호출 시 | 자동 반영 주간 요약, 만료 후보 | 학습 가시성 |
| [_harness/continuous_learning/WARNINGS.md](_harness/continuous_learning/WARNINGS.md) | **분기 1회** | 위험 시나리오 갱신 | 학습 시스템 안전 |
| `./_harness/integrity_alert.md` (프로젝트 로컬) | **세션 시작 시 자동 확인** | 매니페스트 불일치 발생 여부 | 변조 감지 즉시 대응 |
| [.git/hooks/pre-commit](.git/hooks/pre-commit) | **분기 1회** | 시크릿 마스킹 후처리, 직접 쓰기 차단 작동 | 커밋 시 누출 차단 |

### 정기 점검 체크리스트

- [ ] **월간**: `permissions.md`, `whitelist.yaml`, `model_switch.py` 매핑 검토
- [ ] **분기**: `secret_patterns.json`, `bash_patterns.json`, `WARNINGS.md`, pre-commit hook 작동 시뮬레이션
- [ ] **단계 종료 시**: `plan_risks.md` 재평가, `review_report.md` archive 이동, `history.md` 누락 항목 보충
- [ ] **훅 변경 시**: `update_manifest.sh` 자동 실행 확인, `~/.claude/manifest_root.sha256` 권한 600 유지
- [ ] **시크릿 추가 시**: `.env.example` 슬롯 추가 → 동적 마스킹 자동 등록 확인

---

## 7. 보안 정책 결정 사항 (현행)

| 정책 | 결정 | 근거 | 재검토 시점 |
|---|---|---|---|
| Python 경로 | `/usr/bin/python3` 고정 (3.9.6) | 가상환경/brew 혼용 회피 | Python 메이저 업그레이드 시 |
| GPG signed commit | **미도입** | 초기 운영 부담 최소화 | 7일 운영 무사고 후 (10단계 이후) |
| 매니페스트 신뢰 루트 보호 | `chmod 600` | GPG 미도입 대안 | GPG 전환 시 |
| 시크릿 마스킹 | `safe_write.py` 단일 진입점 (3단계 후) | 다양한 우회 경로 차단 | 분기 1회 패턴 점검 |
| `.env` 위치 | 글로벌 `_harness/projects/{프로젝트명}/.env` (시크릿 중앙 보관) | 프로젝트 격리 + Git 강제 제외 | 변경 없음 |
| 자연어 인젝션 검사 | **미도입** (사용자 결정) | 향후 검토 | 향후 결정 |
| L4 Bash 차단 | 차단 대신 의미 토큰 + 5초 카운트다운 (사용자 결정) | 인지 비용으로 갈음 | 향후 결정 |
| Continuous Learning 자동 반영 범위 | whitelist 카테고리만 (CLAUDE.md/rules/agents/skills/hooks/commands는 절대 자동 반영 ❌) | 핵심 정책 보호 | 월 1회 분류 점검 |
| `cautions.md` 로드 정책 | CLAUDE.md 자동 포함 ❌ → `/se:learn audit` 시에만 로드 | 토큰 비용 + 명시적 점검 강제 | 9단계 운영 4주 후 |

> 전체 리스크 표와 감수 리스크는 [_harness/security_engineer/plan_risks.md](_harness/security_engineer/plan_risks.md) 참조.

---

## 8. 토큰 비용 가드 (v5 신규)

| 메커니즘 | 적용 위치 | 효과 |
|---|---|---|
| `plan.md` 슬라이싱 | execute 단계마다 `plan/{N}.md` 1개만 로드 | 단계당 입력 토큰 5~10K 절감 |
| 리스크 표 분리 | `plan_risks.md` review/doc만 로드 | 비판/실행 라운드당 1~2K 절감 |
| `/se:critique --diff` | 직전 라운드 변경분 git diff만 입력 | 비판 라운드 N회 = N배 입력 폭증 회피 |
| `/se:backup` skip | mtime 결정론 비교, 변경 없으면 즉시 종료 | 일일 5~10회 호출 시 80% skip 가능 |
| `merge_history.py` 결정론 | LLM 호출 없이 단순 concat + 시간순 정렬 | 통합 호출 자체 비용 0 |
| `cautions.md` 분리 | CLAUDE.md 자동 포함 ❌ | 매 세션 1~2K 고정 비용 제거 |
| `review_report` 압축 | Haiku 50줄 미만 + 원본 archive | doc 단계 누적 토큰 70% 절감 |
| 의무 로드 표 (위 §2) | 단계별 1~2개 파일만 자동 로드 | 단계당 8~12K 고정 비용 제거 |

---

## 9. 심볼릭 링크 설정

```bash
# 이미 설정 완료 — 아래는 재설정이 필요할 때만 사용
ln -s /Users/pole/scripts/harness/harness/CLAUDE.md ~/.claude/CLAUDE.md
ln -s /Users/pole/scripts/harness/harness/hooks/model_switch.py ~/.claude/hooks/model_switch.py
ln -s /Users/pole/scripts/harness/harness/commands/se ~/.claude/commands/se
ln -s /Users/pole/scripts/harness/harness/commands/teacher ~/.claude/commands/teacher

# (이후 단계에서 추가)
ln -s /Users/pole/scripts/harness/harness/agents/code-security-reviewer.md ~/.claude/agents/code-security-reviewer.md
```

확인:
```bash
ls -la ~/.claude/CLAUDE.md ~/.claude/hooks/ ~/.claude/commands/
```

---

## 10. 오픈소스 참고

[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 참고하여 커스텀 구성.

| 요구사항 | 오픈소스 | 이 레포 |
|---|---|---|
| `history.md` 프로젝트 이력 추적 | ❌ | ✅ |
| 기본 언어 한국어 | ❌ (영어) | ✅ |
| 페르소나 분리 | ❌ | ✅ (보안엔지니어 / 학부생) |
| 계획 에이전트 | △ (planner, 범용) | ✅ (보안 특화, Opus) |
| 비판 에이전트 + 루프 | ❌ | ✅ (`--diff` 옵션 포함) |
| 실행 에이전트 + SBOM | △ (SBOM 없음) | ✅ |
| 검토 에이전트 + 압축 archive | △ (부분적) | ✅ |
| 문서화 에이전트 (4 타입) | ❌ | ✅ |
| 단계별 권한 관리 md | ❌ | ✅ |
| 훅 기반 모델 자동 전환 | ❌ | ✅ |
| 시크릿 마스킹 단일 진입점 | ❌ | ✅ (3단계 구현 예정) |
| 매니페스트 3단계 신뢰 루트 | ❌ | ✅ (2단계 구현 예정) |
| `/se:note` + decisions_index | ❌ | ✅ (9단계 구현 예정) |
| 토큰 비용 가드 (슬라이싱·skip·diff) | ❌ | ✅ (v5 신규) |

---

## 11. 빠른 시작

1. 레포 clone 및 심볼릭 링크 설정 (위 §9)
2. 새 프로젝트 시크릿: `cp .env.example /Users/pole/scripts/harness/harness/_harness/projects/{프로젝트명}/.env` → 값 채움 (Git 제외 강제, 글로벌 보관)
3. 새 프로젝트 작업 디렉토리로 이동(`cd <프로젝트 루트>`) — 슬래시 커맨드 실행 시 그 자리에 `./_harness/` 가 자동 생성된다.
4. 워크플로 시작: `/se:plan <목표>` → `/se:critique` → `/se:confirm` → `/se:execute 1`
5. 진행 상태 확인: `./_harness/security_engineer/plan.md` 로드맵 표 (해당 프로젝트의 로컬 산출물)
6. 세션 재개: `./_harness/history.md` 가장 위 항목부터 읽기 (해당 프로젝트의 로컬 산출물)
7. 여러 프로젝트의 산출물을 한 번에 보고 싶으면 `/se:doc --central` 또는 `/teacher:doc` 중앙화 옵션으로 글로벌 `_harness/{persona}/docs/central/` 에 수합한다.

---

## 12. 도움말 / 변경 이력

- 글로벌 진행 이력(레거시 + 하네스 변경 로그): [_harness/history.md](_harness/history.md)
- 프로젝트별 진행 이력: 각 프로젝트의 `./_harness/history.md`
- 글로벌 정의 — 권한·정책: [_harness/permissions.md](_harness/permissions.md)
- 글로벌 정의 — 실행 라이브러리: [_harness/security_engineer/execute_library.md](_harness/security_engineer/execute_library.md)
- 프로젝트별 현 계획: 각 프로젝트의 `./_harness/security_engineer/plan.md`
- 프로젝트별 리스크: 각 프로젝트의 `./_harness/security_engineer/plan_risks.md`
