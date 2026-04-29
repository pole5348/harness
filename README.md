# Harness Engineering

> Claude Code 하네스 엔지니어링 기반의 프롬프트 관리 레포입니다.
> CLAUDE.md 변경 이력을 Git으로 추적하고, 페르소나별 에이전트 워크플로를 정의합니다.
> 토큰 비용을 의식한 슬라이싱·diff·skip 메커니즘을 v5에서 도입했습니다.
> v5.2부터 **Windows 환경 지원** + **Karpathy 4원칙**(Think Before / Simplicity / Surgical / Goal-Driven) 의무 적용 + **`.claude-plugin/plugin.json`** 패키징 추가.
> v5.3에서 **macOS/Linux/Windows 환경 일원화** — 모든 절대경로를 `~/.claude/...` 로 통일. `scripts/setup.{sh,ps1}` 단일 명령으로 OS별 링크 자동 구성.

---

## 1. 디렉토리 구조 (v5.2)

> **경로 규약 (v5.1 정의/산출물 분리, v5.3 OS-비의존 일원화)**:
> - **정의 파일**(에이전트 시스템 프롬프트, `permissions.md`, `execute_library.md`, `karpathy_guidelines.md`)은 글로벌 위치 `~/.claude/_harness/` 또는 `~/.claude/rules/` 에서 참조한다. 실제 파일은 하네스 레포에 있고 setup 스크립트가 만든 symlink/junction 으로 연결된다. **OS별 절대경로 표기는 일체 사용하지 않는다.**
> - **산출물**(`history.md`, `plan.md`, `plan/`, `plan_risks.md`, `sbom_report.md`, `review_report.md`, `docs/` 등)은 **현재 작업 디렉토리(CWD) 기준 `./_harness/`** 에 저장된다 — 즉 프로젝트마다 `_harness/`가 따로 생긴다. 디렉토리가 없으면 자동 생성.
> - 여러 프로젝트의 산출물을 한 곳에서 보고 싶을 때는 `/harness:doc --central` (또는 학부생 `/teacher:doc` 중앙화 옵션)으로 글로벌 `_harness/{persona}/docs/central/` 에 수합한다.

### 글로벌 레포 (이 레포 = 정의·훅·커맨드)

```
harness/
├── CLAUDE.md                           # 글로벌 지침 (↔ ~/.claude/CLAUDE.md 심볼릭/하드링크)
├── README.md                           # 본 문서
├── .env.example                        # 시크릿 슬롯 템플릿 (Git 추적)
├── .gitignore                          # 시크릿/격리/임시 파일 제외 규칙
├── .claude-plugin/                     # ★ v5.2 — Claude Code 플러그인 패키징 (팀 배포용)
│   └── plugin.json                     # 플러그인 메타데이터 (commands/hooks/rules 묶음)
├── hooks/                              # 훅 스크립트 (↔ ~/.claude/hooks/ 심볼릭/하드링크)
│   ├── model_switch.py                 # UserPromptSubmit — 커맨드별 모델 전환 (macOS/Linux)
│   ├── model_switch.ps1                # ★ v5.2 — Windows PowerShell 버전 (Python 미설치 환경)
│   ├── session_start.py                # SessionStart — 매니페스트 검증 (2단계)
│   ├── session_stop.py                 # Stop — 메타데이터 기록 (5단계)
│   ├── bash_safety.py                  # PreToolUse Bash — L1~L4 위험도 (6단계)
│   ├── manifest.sha256                 # 훅 파일 SHA256 (2단계)
│   └── lib/
│       ├── safe_write.py               # history/status 단일 마스킹 진입점 (3단계)
│       ├── secret_patterns.json        # 정적 시크릿 패턴 (3단계)
│       └── bash_patterns.json          # Bash 위험 패턴 (6단계)
├── commands/                           # 슬래시 커맨드 (↔ ~/.claude/commands/ 심볼릭/junction)
│   ├── se/                             # 보안 엔지니어
│   │   ├── plan.md, critique.md, confirm.md, execute.md, review.md, doc.md
│   │   ├── backup.md                   # /harness:backup (4단계)
│   │   ├── summary.md                  # /harness:summary (5단계)
│   │   ├── note.md                     # /harness:note (9단계)
│   │   └── learn.md, learn-rollback.md, learn-audit.md, learn-cleanup.md  # (9단계)
│   └── teacher/                        # 학부생
│       ├── ask.md
│       └── doc.md
├── agents/                             # 서브에이전트 정의 (↔ ~/.claude/agents/ 심볼릭)
│   └── code-security-reviewer.md       # (8단계)
├── rules/                              # 코딩·보안 규칙
│   └── common/
│       ├── security.md                 # 보안 코딩 규칙 (7단계)
│       └── karpathy_guidelines.md      # ★ v5.2 — LLM 코딩 4원칙 (execute 의무 로드)
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
    │   ├── cautions.md                 # CLAUDE.md 자동 포함 ❌, /harness:learn audit 시에만 로드
    │   ├── WARNINGS.md
    │   ├── quarantine/                 # Git 제외
    │   └── archive/{YYYYMM}/           # 30일 만료 후 이동
    ├── projects/                       # [설정] 프로젝트별 .env (Git 제외)
    │   └── {프로젝트명}/.env
    ├── security_engineer/
    │   ├── 01_plan.md ~ 05_document.md  # [정의] 페르소나 단계별 에이전트 정의
    │   ├── execute_library.md          # [정의] 외부 라이브러리·MCP 라이브러리
    │   └── docs/central/               # [수합] /harness:doc --central 중앙화 산출물
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
    ├── status.md                       # /harness:backup 스냅샷 (4단계)
    ├── integrity_alert.md              # 매니페스트 불일치 알림 (2단계)
    ├── security_engineer/
    │   ├── plan.md                     # ★ 슬림 — 헤더+로드맵+링크만
    │   ├── plan_risks.md               # ★ 리스크 표 분리 (review/doc 시에만 로드)
    │   ├── plan/01.md ~ 10.md          # ★ 단계별 본문 (execute가 자기 단계만 로드)
    │   ├── sbom_report.md              # 외부 라이브러리 사용 시 자동 기록
    │   ├── review_report.md            # 최신 1개 + diff 로그 (압축 요약 50줄 미만)
    │   ├── archive/{YYYYMM}/           # review_report 원본 보관
    │   └── docs/                       # /harness:doc 산출물 (이 프로젝트 한정)
    └── student/
        └── docs/                       # /teacher:doc 학습 노트 (이 프로젝트 한정)
```

> **레거시 노트**: 2026-04-26 이전에 글로벌 `_harness/` 안에 누적된 산출물(`history.md`, `plan.md`, `plan/`, `plan_risks.md`, `review_report.md`)은 그대로 두고, 새 프로젝트부터 위 분리 규칙을 적용한다.

---

## 2. 단계별 파일 로드·수정 매트릭스

> **토큰 가드**: 단계 진입 시 의무 로드 파일을 1~2개로 제한. 그 외는 변경/필요 시점에만.
> **경로 표기**: `./_harness/...` 는 프로젝트 로컬(CWD), 그 외(예: `permissions.md`, `01_plan.md`, `execute_library.md`, `karpathy_guidelines.md`, `cautions.md`, `whitelist.yaml`)는 글로벌 정의(`~/.claude/_harness/...` 또는 `~/.claude/rules/...`).

| 슬래시 커맨드 | 모델 | 의무 로드 (자동) | 조건부 로드 | 자동 수정 파일 |
|---|---|---|---|---|
| `/harness:plan` | Opus 4.7 | `01_plan.md`(글로벌, **Assumptions·Verification 템플릿 포함 v5.2**), (이전) `./_harness/security_engineer/plan.md` | 없음 | (대화에만 — 확정 전 미저장) |
| `/harness:critique` | Opus 4.7 | `02_critique.md`(글로벌, **Karpathy 위반 자동 검출 v5.2**), `./_harness/security_engineer/plan.md`(슬림) + 대상 `./_harness/security_engineer/plan/{N}.md` 1개 | `--diff` 모드: `git diff` 직전 라운드만 | `./_harness/history.md` (비판 이력 추가) |
| `/harness:confirm` | Sonnet 4.6 | `commands/harness/confirm.md` 절차 | 없음 | `./_harness/security_engineer/{plan.md, plan/{N}.md, plan_risks.md}`, `./_harness/history.md` |
| `/harness:execute N` | Sonnet 4.6 | `03_execute.md`(글로벌), `./_harness/security_engineer/plan/{N}.md` 1개, **`rules/common/karpathy_guidelines.md`(글로벌, v5.2)** | `execute_library.md`(글로벌, 외부 의존성 시), `permissions.md`(글로벌, 권한 변경 시), `rules/common/security.md`(7단계 후) | 단계 산출물, `./_harness/security_engineer/sbom_report.md`, `./_harness/history.md`, `./_harness/security_engineer/plan.md` 로드맵 체크 |
| `/harness:review` | Sonnet 4.6 | `04_review.md`(글로벌), 단계 산출물, `./_harness/security_engineer/plan_risks.md` | `./_harness/security_engineer/sbom_report.md`, `./_harness/security_engineer/archive/`(필요 시) | `./_harness/security_engineer/review_report.md` (압축 요약), `./_harness/security_engineer/archive/{YYYYMM}/` (원본 이동) |
| `/harness:doc [A/B/C/D]` | Haiku 4.5 | `05_document.md`(글로벌), `./_harness/security_engineer/{review_report.md, plan.md(슬림), plan_risks.md}` | 없음 | 기본 `./_harness/security_engineer/docs/` (프로젝트 로컬). `--central` 시 글로벌 `_harness/security_engineer/docs/central/` |
| `/harness:backup` | Sonnet 4.6 | `commands/harness/backup.md` 절차 | (변경 없으면 즉시 skip) | `./_harness/status.md` (변경 시에만), `./_harness/history.md` 통합 |
| `/harness:summary` | Sonnet 4.6 | `commands/harness/summary.md` + 트랜스크립트 | 없음 | `./_harness/security_engineer/docs/summary_*.md` |
| `/harness:note <type>` | Sonnet 4.6 | `commands/harness/note.md` + 직전 10분 메타데이터 | `quarantine/`(글로벌, 외부 출처 발견 시) | `decisions_index.md`(글로벌) 또는 `quarantine/`(글로벌) |
| `/harness:learn sonnet\|opus` | 인자 따라 | `commands/harness/learn.md`, `quarantine/`(글로벌) | 없음 | `quarantine/`(글로벌, 수락/거부 표시) |
| `/harness:learn audit` | Sonnet 4.6 | `commands/harness/learn-audit.md`, `cautions.md`(글로벌), `decisions_index.md`(글로벌) | 없음 | `cautions.md`(글로벌, 점검 결과 추가) |
| `/harness:learn cleanup` | Sonnet 4.6 | `commands/harness/learn-cleanup.md` | `quarantine/`(글로벌), `cautions.md`(글로벌) | `archive/{YYYYMM}/`(글로벌) 이동 |
| `/harness:learn rollback <hash>` | Sonnet 4.6 | `commands/harness/learn-rollback.md` + git 로그 | 없음 | git revert 커밋 |
| `/teacher:ask` | Sonnet 4.6 | `01_ask.md`(글로벌) | 없음 | (대화만) |
| `/teacher:doc` | Sonnet 4.6 | `02_document.md`(글로벌) | 없음 | 기본 `./_harness/student/docs/` (프로젝트 로컬). 중앙화 시 글로벌 `_harness/student/docs/central/` |

> **CLAUDE.md는 모든 세션에서 자동 로드**. 그 외 파일은 위 표에 명시된 경우에만 로드된다.

---

## 3. 워크플로 시나리오

### 보안 엔지니어 표준 진행

```
/harness:plan 취약점 스캐너 개발          ← Opus, plan.md 슬림 + 단계 본문 작성
/harness:critique                         ← Opus, plan.md + 단계 본문 비판
/harness:plan 수정사항 반영                ← Opus, 재계획
/harness:critique --diff                  ← Opus, 직전 라운드 변경분만 비판 (토큰 절약)
/harness:confirm                          ← Sonnet, plan.md+plan/+plan_risks.md 저장
/harness:execute 1                        ← Sonnet, plan/01.md만 로드 후 실행
/harness:review                           ← Sonnet, 산출물+plan_risks 로드, review_report 압축
/harness:doc B                            ← Haiku, 외부 보안 리포트 생성
/harness:backup                           ← Sonnet, 변경 없으면 즉시 skip
```

### 학부생 Q&A (보안 작업 중 즉시 전환)

```
/teacher:ask JWT 토큰이 뭐야?        ← Sonnet
/teacher:doc 오늘 배운 JWT 내용 정리 ← Sonnet
```

### Continuous Learning (9단계 도입 후)

```
/harness:note decision <내용>             ← 결론 마킹 → decisions_index.md
/harness:note rationale <내용>            ← 판단 근거 마킹
/harness:learn sonnet                     ← quarantine 검토·수락·거부
/harness:learn audit                      ← 주간 자동 반영 점검 (cautions.md 이때만 로드)
/harness:learn cleanup                    ← 30일 만료 archive 이동
/harness:learn rollback <commit-hash>     ← 잘못 반영된 자동 학습 되돌리기
```

---

## 4. 모델 할당 (자동 전환 — `model_switch.py` / `model_switch.ps1`)

> **OS별 훅**: Windows 환경은 `hooks/model_switch.ps1` (PowerShell), macOS/Linux 환경은 `hooks/model_switch.py` (Python 3) 사용. 두 파일은 동일한 로직·매핑을 가지며 `~/.claude/settings.json` 의 `UserPromptSubmit` 훅으로 등록한다.

| 커맨드 | 모델 | 단가 비교 |
|---|---|---|
| `/harness:plan`, `/harness:critique` | claude-opus-4-7 | Sonnet의 약 5배 |
| `/harness:confirm`, `/harness:execute`, `/harness:review`, `/harness:backup`, `/harness:summary`, `/harness:note`, `/harness:learn (rollback/audit/cleanup)` | claude-sonnet-4-6 | 기준 |
| `/harness:learn opus` | claude-opus-4-7 | 사용자 명시 시 |
| `/harness:learn sonnet` | claude-sonnet-4-6 | 사용자 명시 시 |
| `/harness:doc` | claude-haiku-4-5-20251001 | Sonnet의 약 1/4 |
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
| ★★ | [rules/common/karpathy_guidelines.md](rules/common/karpathy_guidelines.md) | 글로벌 정의 | `/harness:execute` 단계 의무 로드 (v5.2 신규) |
| ★★ | `./_harness/security_engineer/plan_risks.md` | 프로젝트 산출물 | review/doc 단계 또는 의사결정 시 |
| ★ | [_harness/security_engineer/execute_library.md](_harness/security_engineer/execute_library.md) | 글로벌 정의 | 외부 라이브러리·MCP 사용 시 |
| ★ | `./_harness/security_engineer/review_report.md` | 프로젝트 산출물 | 검토 직후 |
| ★ | [.env.example](.env.example) | 글로벌 정의 | 새 시크릿 슬롯 추가 시 |
| ★ | [.claude-plugin/plugin.json](.claude-plugin/plugin.json) | 글로벌 정의 | 팀 배포·플러그인 메타데이터 (v5.2 신규) |

> 프로젝트 산출물 경로(`./_harness/...`)는 슬래시 커맨드를 실행한 작업 디렉토리(CWD) 기준이라 프로젝트마다 다르다. 글로벌 정의 파일은 모두 `~/.claude/...` 로 참조되며, 실제 파일은 하네스 레포의 단일 사본을 setup 스크립트가 link 로 연결한다.

---

## 6. Security Guardrails (사용자 주기적 트래킹·수정 권장)

> **다음 파일들은 보안 핵심 자산입니다.** 변경 시 반드시 git diff 검토 + history.md 기록.
> 정기 점검 주기를 권장합니다.

| 파일 | 점검 주기 | 점검 내용 | 변경 시 영향 |
|---|---|---|---|
| [_harness/permissions.md](_harness/permissions.md) | **월 1회** | 단계별 허용 도구·금지 항목, GPG 도입 시점, Python 경로 | 모든 단계의 권한 경계 |
| [.gitignore](.gitignore) | **변경 시 즉시** | `.env*` 패턴, quarantine, history 분기 | 시크릿 누출 직접 영향 |
| [.env.example](.env.example) | 새 시크릿 추가 시 | 슬롯 정의 (값 없음) | 동적 마스킹 패턴 등록 대상 |
| [hooks/model_switch.py](hooks/model_switch.py) | 신규 커맨드 추가 시 | 매핑 정확성, regex 안정성 (macOS/Linux) | 모델 자동 전환 핵심 |
| [hooks/model_switch.ps1](hooks/model_switch.ps1) | 신규 커맨드 추가 시 | 매핑 정확성, regex 안정성 (Windows) | 모델 자동 전환 핵심 — `model_switch.py` 와 동기화 필수 |
| [rules/common/karpathy_guidelines.md](rules/common/karpathy_guidelines.md) | **반기 1회** | 4원칙 정의 변경 여부, 페르소나 적용 우선순위 | `/harness:execute` 코딩 품질 가드 |
| [hooks/manifest.sha256](hooks/manifest.sha256) | **훅 변경 시 즉시** (자동) | SHA256 일치 여부 | 훅 변조 검증 |
| [~/.claude/manifest_root.sha256](~/.claude/manifest_root.sha256) | **훅 변경 시 즉시** (자동) | 신뢰 루트 (chmod 600) | 매니페스트 변조 검증 |
| [hooks/lib/safe_write.py](hooks/lib/safe_write.py) | 시크릿 패턴 추가 시 | 정적/동적 마스킹 적용 범위 | history/status 누출 차단 |
| [hooks/lib/secret_patterns.json](hooks/lib/secret_patterns.json) | **분기 1회** (CVE/신규 패턴 반영) | API 키 신규 형식 추가 | 마스킹 누락 방지 |
| [hooks/lib/bash_patterns.json](hooks/lib/bash_patterns.json) | **분기 1회** | L4 위험 명령 패턴 누락 여부 | 시스템 손상 방지 |
| `./_harness/security_engineer/plan_risks.md` (프로젝트 로컬) | **단계 종료 시** | 식별 리스크 vs 감수 리스크 재평가 | 리스크 가시성 |
| [_harness/continuous_learning/whitelist.yaml](_harness/continuous_learning/whitelist.yaml) | **월 1회** | auto_apply ↔ manual_only 분류 정확성 | 자동 학습 안전 경계 |
| [_harness/continuous_learning/cautions.md](_harness/continuous_learning/cautions.md) | `/harness:learn audit` 호출 시 | 자동 반영 주간 요약, 만료 후보 | 학습 가시성 |
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
| Python 경로 (macOS/Linux) | `/usr/bin/python3` 고정 (3.9.6) | 가상환경/brew 혼용 회피 | Python 메이저 업그레이드 시 |
| 훅 런타임 (Windows) | PowerShell 5.1 + `model_switch.ps1` | Python 미설치 환경 대응 (v5.2) | Python 도입 시 .py 로 전환 가능 |
| GPG signed commit | **미도입** | 초기 운영 부담 최소화 | 7일 운영 무사고 후 (10단계 이후) |
| 매니페스트 신뢰 루트 보호 | `chmod 600` | GPG 미도입 대안 | GPG 전환 시 |
| 시크릿 마스킹 | `safe_write.py` 단일 진입점 (3단계 후) | 다양한 우회 경로 차단 | 분기 1회 패턴 점검 |
| `.env` 위치 | 글로벌 `_harness/projects/{프로젝트명}/.env` (시크릿 중앙 보관) | 프로젝트 격리 + Git 강제 제외 | 변경 없음 |
| 자연어 인젝션 검사 | **미도입** (사용자 결정) | 향후 검토 | 향후 결정 |
| L4 Bash 차단 | 차단 대신 의미 토큰 + 5초 카운트다운 (사용자 결정) | 인지 비용으로 갈음 | 향후 결정 |
| Continuous Learning 자동 반영 범위 | whitelist 카테고리만 (CLAUDE.md/rules/agents/skills/hooks/commands는 절대 자동 반영 ❌) | 핵심 정책 보호 | 월 1회 분류 점검 |
| `cautions.md` 로드 정책 | CLAUDE.md 자동 포함 ❌ → `/harness:learn audit` 시에만 로드 | 토큰 비용 + 명시적 점검 강제 | 9단계 운영 4주 후 |

> 전체 리스크 표와 감수 리스크는 [_harness/security_engineer/plan_risks.md](_harness/security_engineer/plan_risks.md) 참조.

---

## 8. 토큰 비용 가드 (v5 신규)

| 메커니즘 | 적용 위치 | 효과 |
|---|---|---|
| `plan.md` 슬라이싱 | execute 단계마다 `plan/{N}.md` 1개만 로드 | 단계당 입력 토큰 5~10K 절감 |
| 리스크 표 분리 | `plan_risks.md` review/doc만 로드 | 비판/실행 라운드당 1~2K 절감 |
| `/harness:critique --diff` | 직전 라운드 변경분 git diff만 입력 | 비판 라운드 N회 = N배 입력 폭증 회피 |
| `/harness:backup` skip | mtime 결정론 비교, 변경 없으면 즉시 종료 | 일일 5~10회 호출 시 80% skip 가능 |
| `merge_history.py` 결정론 | LLM 호출 없이 단순 concat + 시간순 정렬 | 통합 호출 자체 비용 0 |
| `cautions.md` 분리 | CLAUDE.md 자동 포함 ❌ | 매 세션 1~2K 고정 비용 제거 |
| `review_report` 압축 | Haiku 50줄 미만 + 원본 archive | doc 단계 누적 토큰 70% 절감 |
| 의무 로드 표 (위 §2) | 단계별 1~2개 파일만 자동 로드 | 단계당 8~12K 고정 비용 제거 |
| Karpathy Verification 루프 (v5.2) | `/harness:execute` 단계 검증 통과까지 자율 반복 | 사용자 확인 라운드 트립 감소 → 라운드당 5~15K 절감 |
| Karpathy Assumptions 사전 확정 (v5.2) | `/harness:plan` 단계 가정 표면화 | 후반 재작업으로 인한 plan→execute 재진입 비용 회피 |

---

## 9. 설치 — 단일 명령 (v5.3 cross-platform)

> **핵심 개선**: 슬래시 커맨드·CLAUDE.md·에이전트 정의는 모두 OS-비의존적인 `~/.claude/...` 경로로 참조한다. setup 스크립트가 OS에 맞는 링크(symlink/junction/hardlink) 를 자동 생성한다.

### macOS / Linux

```bash
cd <harness 레포>
./scripts/setup.sh
```

스크립트가 처리하는 것:
- `~/.claude/{CLAUDE.md, commands/harness, commands/teacher, _harness, rules, hooks/model_switch.py}` symlink 생성
- `~/.claude/settings.json` 에 `UserPromptSubmit` 훅 자동 등록 (이미 있으면 skip)

### Windows

```powershell
cd <harness 레포>
powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
```

스크립트가 처리하는 것:
- 디렉토리(`commands/harness`, `commands/teacher`, `_harness`, `rules`) → **junction**
- 파일(`CLAUDE.md`, `hooks/model_switch.ps1`) → **hardlink** (같은 볼륨 필수)
- `~/.claude/settings.json` 에 PowerShell 훅 자동 등록

### 검증 (양 OS 공통)

```bash
# 새 Claude Code 세션 열기 후 슬래시 커맨드 실행
/harness:plan 테스트
# settings.json 의 model 이 claude-opus-4-7 로 자동 전환되는지 확인
```

### 링크 구조 (양 OS 동일)

```
~/.claude/
├── CLAUDE.md          → <harness>/CLAUDE.md
├── commands/harness        → <harness>/commands/harness
├── commands/teacher   → <harness>/commands/teacher
├── _harness           → <harness>/_harness          # 정의 파일 디렉토리 전체
├── rules              → <harness>/rules             # karpathy_guidelines 등
└── hooks/
    ├── model_switch.py    → <harness>/hooks/model_switch.py    (macOS/Linux)
    └── model_switch.ps1   → <harness>/hooks/model_switch.ps1   (Windows)
```

> **링크 주의사항**:
> - macOS/Linux symlink: source 이동/삭제 시 끊어짐. 그럴 때 `setup.sh` 재실행.
> - Windows hardlink: 양쪽 어느 쪽 편집해도 동기화. **삭제 후 새로 생성** 시 끊어짐 → `setup.ps1` 재실행.
> - Windows junction: source 디렉토리 이름/위치 변경 시 끊어짐 → `setup.ps1` 재실행.

---

## 10. 오픈소스 참고

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 워크플로/구조 참고하여 커스텀 구성.
- [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — **v5.2부터 통합**. Karpathy의 LLM 코딩 4원칙을 `rules/common/karpathy_guidelines.md` 로 가져와 `/harness:execute` 의무 로드.

| 요구사항 | everything-claude-code | karpathy-skills | 이 레포 |
|---|---|---|---|
| `history.md` 프로젝트 이력 추적 | ❌ | ❌ | ✅ |
| 기본 언어 한국어 | ❌ (영어) | ❌ (영어) | ✅ |
| 페르소나 분리 | ❌ | ❌ | ✅ (보안엔지니어 / 학부생) |
| 계획 에이전트 | △ (planner, 범용) | ❌ | ✅ (보안 특화, Opus) |
| 비판 에이전트 + 루프 | ❌ | ❌ | ✅ (`--diff` 옵션 포함) |
| 실행 에이전트 + SBOM | △ (SBOM 없음) | ❌ | ✅ |
| 검토 에이전트 + 압축 archive | △ (부분적) | ❌ | ✅ |
| 문서화 에이전트 (4 타입) | ❌ | ❌ | ✅ |
| 단계별 권한 관리 md | ❌ | ❌ | ✅ |
| 훅 기반 모델 자동 전환 | ❌ | ❌ | ✅ (Python + PowerShell) |
| 시크릿 마스킹 단일 진입점 | ❌ | ❌ | ✅ (3단계 구현 예정) |
| 매니페스트 3단계 신뢰 루트 | ❌ | ❌ | ✅ (2단계 구현 예정) |
| `/harness:note` + decisions_index | ❌ | ❌ | ✅ (9단계 구현 예정) |
| 토큰 비용 가드 (슬라이싱·skip·diff) | ❌ | ❌ | ✅ (v5 신규) |
| LLM 코딩 4원칙 (Think/Simplicity/Surgical/Goal) | ❌ | ✅ (단일 skill) | ✅ (execute 의무 로드, critique 검출, plan 템플릿 강제 — v5.2) |
| Plugin 패키징 (`.claude-plugin/plugin.json`) | ❌ | ✅ (skills) | ✅ (commands+hooks+rules — v5.2) |
| Windows 네이티브 지원 | ❌ | ❌ | ✅ (PowerShell 훅 + junction/hardlink — v5.2) |

---

## 11. 빠른 시작

1. 레포 clone 후 setup 스크립트 1회 실행 (위 §9):
   - macOS/Linux: `./scripts/setup.sh`
   - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1`
2. 새 프로젝트 시크릿: `~/.claude/_harness/projects/{프로젝트명}/.env` 에 값 채움 (Git 제외 강제, 하네스 레포의 `_harness/projects/` 와 동일 위치).
3. 새 프로젝트 작업 디렉토리로 이동(`cd <프로젝트 루트>`) — 슬래시 커맨드 실행 시 그 자리에 `./_harness/` 가 자동 생성된다.
4. 워크플로 시작: `/harness:plan <목표>` → `/harness:critique` → `/harness:confirm` → `/harness:execute 1`
   - `/harness:plan` 출력에 **Assumptions 표** + 단계별 **성공 기준 (Verification)** 항목이 포함되는지 확인 (v5.2 강제).
   - `/harness:execute` 진입 시 `Assumptions` 의 "확인 필요" 항목이 모두 확정되었는지 자동 검증.
5. 진행 상태 확인: `./_harness/security_engineer/plan.md` 로드맵 표 (해당 프로젝트의 로컬 산출물)
6. 세션 재개: `./_harness/history.md` 가장 위 항목부터 읽기 (해당 프로젝트의 로컬 산출물)
7. 여러 프로젝트의 산출물을 한 번에 보고 싶으면 `/harness:doc --central` 또는 `/teacher:doc` 중앙화 옵션으로 글로벌 `_harness/{persona}/docs/central/` 에 수합한다.

---

## 12. 도움말 / 변경 이력

- 글로벌 진행 이력(레거시 + 하네스 변경 로그): [_harness/history.md](_harness/history.md)
- 프로젝트별 진행 이력: 각 프로젝트의 `./_harness/history.md`
- 글로벌 정의 — 권한·정책: [_harness/permissions.md](_harness/permissions.md)
- 글로벌 정의 — 실행 라이브러리: [_harness/security_engineer/execute_library.md](_harness/security_engineer/execute_library.md)
- 글로벌 정의 — Karpathy 4원칙: [rules/common/karpathy_guidelines.md](rules/common/karpathy_guidelines.md)
- 플러그인 메타데이터: [.claude-plugin/plugin.json](.claude-plugin/plugin.json)
- 프로젝트별 현 계획: 각 프로젝트의 `./_harness/security_engineer/plan.md`
- 프로젝트별 리스크: 각 프로젝트의 `./_harness/security_engineer/plan_risks.md`

---

## 변경 이력 (주요)

| 버전 | 날짜 | 주요 변경 |
|---|---|---|
| v5.3 | 2026-04-30 | **OS-비의존 일원화** — 모든 OS-specific 절대경로 제거, `~/.claude/...` 통일. `scripts/setup.{sh,ps1}` 단일 명령 설치. main/windows 브랜치 통합 가능 |
| v5.2 | 2026-04-29 | Karpathy 4원칙 통합 (rules/common/karpathy_guidelines.md), `/harness:plan` 템플릿에 Assumptions·Verification 강제, `/harness:critique` Karpathy 위반 검출, `/harness:execute` Surgical 게이트, `.claude-plugin/plugin.json` 패키징 |
| v5.2 | 2026-04-27 | Windows 환경 지원 (PowerShell 훅 `model_switch.ps1`, junction/hardlink 셋업) |
| v5.1 | 2026-04-26 | 정의(글로벌) ↔ 산출물(프로젝트 로컬) 분리 규칙 |
| v5.0 | — | 토큰 비용 가드 (슬라이싱·diff·skip) 도입 |
