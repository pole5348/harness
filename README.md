# Harness Engineering (v5.4)

> Claude Code 기반 **보안 엔지니어 / 학부생 페르소나 워크플로 하네스**.
> `plan → critique → confirm → execute → (auto) → review → doc` 다단계 파이프라인을
> 슬래시 커맨드 + 훅 + 글로벌 정의 파일로 구현하고, 모든 변경 이력을 Git으로 추적합니다.
>
> **v5.4 핵심 추가**
> - `/harness:auto` — Verification 통과까지 자율 루프 실행
> - 표준 문서 템플릿 (`ADR`, `PRD`, `ARCH`, `UI`) — `/harness:doc` 가 자동 사용
> - `bash_safety` 훅 (PreToolUse) — L4 위험 명령 차단
> - `stop_validate` 훅 (Stop) — 세션 종료 시 프로젝트 자동 검증 (npm/pytest/cargo/go)
> - 모든 훅이 macOS·Linux(Python) / Windows(PowerShell) 양쪽 동등 구현
>
> **v5.3 (2026-04-30)** — OS-비의존 일원화. 모든 절대경로를 `~/.claude/...` 로 통일.
> **v5.2 (2026-04-29)** — Karpathy 4원칙 의무 적용. `.claude-plugin/plugin.json` 패키징.
> **v5.1 (2026-04-26)** — 정의(글로벌) ↔ 산출물(프로젝트 로컬) 분리 규칙.
> **v5.0** — 토큰 비용 가드 (슬라이싱·diff·skip).

---

## 목차

1. [핵심 컨셉](#1-핵심-컨셉)
2. [한눈에 보는 워크플로](#2-한눈에-보는-워크플로)
3. [디렉토리 구조](#3-디렉토리-구조)
4. [슬래시 커맨드 — 상세 + 예시](#4-슬래시-커맨드--상세--예시)
5. [자동 모델 전환 (model_switch)](#5-자동-모델-전환-model_switch)
6. [Bash 안전 검사 (bash_safety)](#6-bash-안전-검사-bash_safety)
7. [세션 종료 자동 검증 (stop_validate)](#7-세션-종료-자동-검증-stop_validate)
8. [Karpathy 4원칙](#8-karpathy-4원칙)
9. [표준 문서 템플릿 (ADR/PRD/ARCH/UI)](#9-표준-문서-템플릿-adrprdarchui)
10. [토큰 비용 가드](#10-토큰-비용-가드)
11. [권한 / 보안 정책](#11-권한--보안-정책)
12. [설치 — 단일 명령](#12-설치--단일-명령)
13. [End-to-End 시나리오](#13-end-to-end-시나리오)
14. [참고·트러블슈팅·변경 이력](#14-참고트러블슈팅변경-이력)

---

## 1. 핵심 컨셉

### 1.1. 두 페르소나

| 페르소나 | 네임스페이스 | 역할 |
|---|---|---|
| **보안 엔지니어** | `/harness:*` | PM/PO·보안팀·실행자·리뷰어·기술 라이터를 단계별로 분리한 파이프라인 |
| **학부생** | `/teacher:*` | 사용자가 학부생, Claude가 교수님. 즉석 Q&A + 학습 문서화 |

> **격리 원칙**: 각 페르소나·단계는 독립된 에이전트로 동작한다. 이전 단계의 컨텍스트를 임의로 끌고 오지 않고, 정해진 산출물 파일을 통해서만 정보를 전달한다.

### 1.2. 정의 vs 산출물 분리 (v5.1)

| 종류 | 위치 | 예시 |
|---|---|---|
| **정의** (글로벌, 모든 프로젝트 공유) | `~/.claude/_harness/...`, `~/.claude/rules/...` | `01_plan.md`, `permissions.md`, `karpathy_guidelines.md`, `docs/templates/ADR.md` |
| **산출물** (프로젝트 로컬, CWD 기준) | `./_harness/...` | `plan.md`, `plan/01.md`, `history.md`, `review_report.md`, `docs/`, `auto_state.json` |

> 슬래시 커맨드를 어느 디렉토리에서 실행하느냐에 따라 그 자리에 `./_harness/` 가 자동 생성된다. 프로젝트마다 산출물이 격리된다.

### 1.3. OS-비의존 단일 경로 규약 (v5.3)

- 모든 글로벌 정의는 `~/.claude/...` 로만 참조한다 (절대 경로 직접 표기 금지).
- `~` 는 macOS·Linux=`$HOME`, Windows=`%USERPROFILE%` 로 자동 해석.
- `scripts/setup.{sh,ps1}` 단일 명령으로 OS별 link(symlink/junction/hardlink) 자동 구성.

### 1.4. 자동 모델 전환

`UserPromptSubmit` 훅(`model_switch.py` / `model_switch.ps1`)이 슬래시 커맨드를 감지하여 `~/.claude/settings.json` 의 `model` 필드를 자동 갱신한다 — **사용자가 `/model` 을 수동 호출할 필요 없음**.

---

## 2. 한눈에 보는 워크플로

```
[/harness:plan]      Opus 4.7   ← 가정 표면화 + 단계별 Verification 정의
       │
       ▼
[/harness:critique]  Opus 4.7   ← Karpathy 위반 검출, --diff 모드로 토큰 절약
       │  (루프: 만족할 때까지)
       ▼
[/harness:confirm]   Sonnet 4.6 ← 최종 plan.md + plan/{N}.md + plan_risks.md 저장
       │
       ▼
[/harness:execute N] Sonnet 4.6 ← 단계별 수동 실행 (Karpathy 의무 로드)
   또는
[/harness:auto N..M] Sonnet 4.6 ← Verification 통과까지 자율 루프 (NEW v5.4)
       │
       ▼
[/harness:review]    Sonnet 4.6 ← 종합 검토 리포트 (압축 50줄 미만)
       │
       ▼
[/harness:doc TYPE]  Haiku 4.5  ← ADR/PRD/ARCH/UI 또는 A/B/C/D 채널 문서
```

학부생 페르소나는 보안 엔지니어 작업 중 어디서든 즉시 끼어들 수 있다.

```
[/teacher:ask <질문>]  Sonnet 4.6   ← 교수 모드 즉시 전환
[/teacher:doc <주제>]  Sonnet 4.6   ← 학습 노트로 정리
```

---

## 3. 디렉토리 구조

### 3.1. 글로벌 레포 (정의·훅·커맨드 — 이 레포 자체)

```
harness/
├── CLAUDE.md                              # 글로벌 지침 (← ~/.claude/CLAUDE.md 로 link)
├── README.md                              # 본 문서
├── .env.example                           # 시크릿 슬롯 템플릿 (Git 추적)
├── .gitignore                             # 시크릿/Obsidian/Python 캐시 제외
├── .claude-plugin/
│   └── plugin.json                        # 플러그인 메타데이터 (v5.4.0)
├── commands/                              # 슬래시 커맨드 (← ~/.claude/commands/)
│   ├── harness/
│   │   ├── plan.md, critique.md, confirm.md
│   │   ├── execute.md, auto.md             # ← /harness:auto v5.4 신규
│   │   ├── review.md, doc.md
│   └── teacher/
│       ├── ask.md, doc.md
├── hooks/                                 # 훅 (← ~/.claude/hooks/)
│   ├── model_switch.py / model_switch.ps1   # UserPromptSubmit
│   ├── bash_safety.py / bash_safety.ps1     # PreToolUse(Bash)
│   ├── stop_validate.py / stop_validate.ps1 # Stop
│   └── lib/
│       └── bash_patterns.json             # L4 위험 패턴 정의
├── rules/
│   └── common/
│       └── karpathy_guidelines.md         # LLM 코딩 4원칙 (execute 의무 로드)
├── scripts/
│   ├── setup.sh                           # macOS/Linux 단일 명령 설치
│   └── setup.ps1                          # Windows 단일 명령 설치
└── _harness/                              # 글로벌 정의 (← ~/.claude/_harness/)
    ├── permissions.md                     # 단계별 권한·MCP·금지
    ├── history.md                         # ★ 글로벌 하네스 변경 이력 (레거시)
    ├── security_engineer/
    │   ├── 01_plan.md ~ 05_document.md      # 단계별 에이전트 정의
    │   ├── execute_library.md             # 외부 라이브러리·MCP 카탈로그
    │   └── docs/
    │       └── templates/                 # ★ v5.4 — /harness:doc 표준 템플릿
    │           ├── ADR.md
    │           ├── PRD.md
    │           ├── ARCHITECTURE.md
    │           └── UI_GUIDE.md
    └── student/
        ├── 01_ask.md, 02_document.md
        └── docs/
```

### 3.2. 프로젝트 로컬 (CWD 기준 자동 생성)

```
<프로젝트 루트>/                              # 슬래시 커맨드를 실행한 디렉토리
└── _harness/
    ├── history.md                         # 이 프로젝트의 진행 이력
    ├── security_engineer/
    │   ├── plan.md                        # 슬림 — 헤더+로드맵+링크
    │   ├── plan_risks.md                  # 리스크 표 (review/doc 시에만 로드)
    │   ├── plan/01.md ~ {N}.md            # 단계별 본문 (execute는 1개만 로드)
    │   ├── auto_state.json                # /harness:auto 진행 상태 (v5.4)
    │   ├── sbom_report.md                 # 외부 의존성 사용 시 자동 기록
    │   ├── review_report.md               # 종합 검토 (압축 50줄 미만)
    │   └── docs/
    │       ├── ADR/[YYYY-MM-DD]_*.md
    │       ├── PRD/[YYYY-MM-DD]_*.md
    │       ├── ARCH/[YYYY-MM-DD]_*.md
    │       └── UI/[YYYY-MM-DD]_*.md
    └── student/
        └── docs/[YYYY-MM-DD]_*.md
```

---

## 4. 슬래시 커맨드 — 상세 + 예시

### 4.1. `/harness:plan` — 1단계 계획 수립

| 항목 | 내용 |
|---|---|
| 모델 | `claude-opus-4-7` (자동 전환) |
| 의무 로드 | `~/.claude/_harness/security_engineer/01_plan.md` |
| 산출물 | (대화만 — `/harness:confirm` 전까지 미저장) |

**핵심 동작**: 주제를 받아 (1) Assumptions 표 (Karpathy 1원칙), (2) 단계별 Verification 명령 (Karpathy 4원칙), (3) 사전 식별 리스크를 포함하는 계획을 작성한다.

```bash
/harness:plan 사내 API 게이트웨이의 JWT 검증 모듈 개발
```

**예상 출력 구조**:

```markdown
# 프로젝트 계획: API 게이트웨이 JWT 검증

## 가정 (Assumptions)
| # | 가정 | 영향 | 상태 |
|---|---|---|---|
| A1 | 토큰은 HS256 만 사용 | RS256 미지원 시 알고리즘 분기 불필요 | [ ] 확인 필요 |
| A2 | 시계 동기화는 ±60s 허용 | exp/nbf 허용 오차 결정 | [ ] 확인 필요 |

## 실행 단계
### 1단계: 토큰 파서 구현
- 성공 기준 (Verification):
  - [ ] 검증 명령: `pytest tests/test_jwt_parse.py -v`
  - [ ] 통과 조건: exit 0, "5 passed"
  - [ ] 부정 케이스: 잘못된 서명 → ValueError 발생
```

> **주의**: 이 단계에서는 파일 쓰기·코드 실행이 금지된다 (`permissions.md` 참조). 계획은 대화 영역에만 머문다.

---

### 4.2. `/harness:critique` — 2단계 계획 비판

| 항목 | 내용 |
|---|---|
| 모델 | `claude-opus-4-7` |
| 의무 로드 | `02_critique.md` + `./_harness/security_engineer/plan.md` (슬림) + 대상 단계 1개 |
| 인자 | 없음 / `--diff` / 단계 번호 |
| 산출물 | `./_harness/history.md` 에 비판 이력 추가 |

**핵심 동작**: PM/PO·보안팀·재무팀의 시각으로 계획을 공격한다. Karpathy 위반(과추상화·미확정 가정·누락 Verification)도 자동 검출.

**예시 1 — 전체 비판**:

```bash
/harness:critique
```

**예시 2 — 특정 단계만 비판**:

```bash
/harness:critique 3   # plan/03.md 만 로드해서 비판
```

**예시 3 — diff 모드 (토큰 절약)**:

```bash
/harness:critique --diff
# 직전 라운드(가장 최근 /harness:confirm 커밋)와 HEAD 사이의
# plan/, plan.md, plan_risks.md 변경분만 입력으로 사용
```

> **루프 사용**: 비판이 만족스러울 때까지 `/harness:plan` ↔ `/harness:critique` 를 반복한다. 이력은 `./_harness/history.md` 에 누적된다.

---

### 4.3. `/harness:confirm` — 계획 확정 저장

| 항목 | 내용 |
|---|---|
| 모델 | `claude-sonnet-4-6` |
| 산출물 | `./_harness/security_engineer/{plan.md, plan/{N}.md, plan_risks.md}` + `./_harness/history.md` |

**핵심 동작**: 비판 루프가 끝난 최종 계획만 디스크에 저장. **반드시 "감수해야 할 리스크" 섹션 포함**.

```bash
/harness:confirm
```

**저장 결과**:

```
./_harness/
├── history.md                              # "계획 확정" 이벤트 추가
└── security_engineer/
    ├── plan.md                             # 슬림 — 로드맵 표 + 링크
    ├── plan_risks.md                       # 리스크 표 (분리)
    └── plan/
        ├── 01.md
        ├── 02.md
        └── ...
```

---

### 4.4. `/harness:execute` — 3단계 수동 실행

| 항목 | 내용 |
|---|---|
| 모델 | `claude-sonnet-4-6` |
| 의무 로드 | `03_execute.md` + `plan.md`(헤더만) + `plan/{N}.md` 1개 + `karpathy_guidelines.md` |
| 조건부 로드 | `execute_library.md` (외부 의존성 사용 시), `permissions.md` (권한 변경 시) |
| 인자 | 단계 번호 / 태스크명 / 생략(첫 미완료) |

**예시 1 — 1단계만 실행**:

```bash
/harness:execute 1
```

**예시 2 — 자동 다음 단계 선택**:

```bash
/harness:execute
# plan.md 로드맵에서 첫 [ ] 단계를 자동으로 선택
```

**예시 3 — 태스크명으로 호출**:

```bash
/harness:execute "토큰 파서 구현"
# plan.md 로드맵에서 태스크명 매칭 → 해당 plan/{N}.md 로드
```

**자동 갱신 항목** (실행 후):
- `./_harness/security_engineer/plan.md` 로드맵의 해당 행을 `[x]` + 완료일자
- `./_harness/history.md` 에 실행 결과 기록
- 외부 라이브러리 도입 시 `./_harness/security_engineer/sbom_report.md` 추가

---

### 4.5. `/harness:auto` — 자율 실행 루프 (v5.4 신규)

| 항목 | 내용 |
|---|---|
| 모델 | `claude-sonnet-4-6` |
| 의무 로드 | `03_execute.md` + `karpathy_guidelines.md` + 진입 단계 `plan/{N}.md` |
| 산출물 | `./_harness/security_engineer/auto_state.json` + 단계별 산출물 |
| 인자 | `N` / `N..M` / `--all` / 생략 |

**핵심 차이 (vs `/harness:execute`)**:

| 항목 | `/harness:execute N` | `/harness:auto [범위]` |
|---|---|---|
| 호출 단위 | 단일 단계 | 복수 단계 자율 루프 |
| 검증 실패 시 | 사용자 호출 대기 | 최대 3회 자동 수정 시도 |
| 단계 진입 | 사용자가 다음 단계 호출 | 통과 시 자동 다음 단계 |
| 토큰 비용 | 단계마다 컨텍스트 재설정 | 단일 세션에서 캐시 재활용 (절감) |

**예시 1 — 1단계부터 끝까지**:

```bash
/harness:auto
# 또는
/harness:auto --all
```

**예시 2 — 2~5단계만 자율 진행**:

```bash
/harness:auto 2..5
```

**예시 3 — 권장 사용 (안전 우선)**:

```bash
/harness:execute 1     # 첫 단계는 수동 검증 + 워밍업
/harness:auto 2..      # 2단계부터 자율
```

**자율 루프 알고리즘**:

```
for each step in [N..end]:
  1) plan/{step}.md 로드
  2) Assumptions 표 — "확인 필요" 모두 확정인지 검증
     → 미확정 발견 시 STOP (Karpathy 1원칙)
  3) Verification 섹션 존재 검증
     → 누락 시 STOP (Karpathy 4원칙)
  4) 단계 실행 (Karpathy 4원칙 의무 적용)
  5) 검증 명령 실행
     - 통과 → [x] 처리, history 기록, 다음 step
     - 실패 → 자동 수정 시도 (최대 3회)
     - 3회 실패 → "blocked" 표시, STOP
```

**STOP 조건** (자율 루프 즉시 중단):
1. Assumption 미확정 (1원칙)
2. Verification 섹션 누락 (4원칙)
3. 동일 단계 검증 3회 연속 실패
4. plan/{N}.md 의 모호한 지시 (다중 해석 가능)
5. 외부 의존성 추가 발견 (사용자 승인 필요)
6. `bash_safety` 훅이 명령을 차단

**상태 추적 파일** (`./_harness/security_engineer/auto_state.json`):

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

**세션 종료 시 자동 보고**:

```
[/harness:auto 결과]
- 완료: 단계 1, 2 (2/5)
- 실패: 단계 3 — blocked (3회 실패: <마지막 사유>)
- 미실행: 단계 4, 5
- 다음 행동: <STOP 사유에 따른 권장 명령>
```

---

### 4.6. `/harness:review` — 4단계 종합 검토

| 항목 | 내용 |
|---|---|
| 모델 | `claude-sonnet-4-6` |
| 의무 로드 | `04_review.md` + 단계 산출물 + `plan_risks.md` |
| 조건부 로드 | `sbom_report.md` (외부 의존성 있을 때) |
| 산출물 | `./_harness/security_engineer/review_report.md` (압축 요약) |

```bash
/harness:review
```

**예시 — 추가 검토 범위 지정**:

```bash
/harness:review 인증 흐름과 시크릿 저장 위치를 중점 점검
```

> 압축된 50줄 미만 요약을 `review_report.md` 에 저장하고, 원본은 `./_harness/security_engineer/archive/{YYYYMM}/` 로 이동.

---

### 4.7. `/harness:doc` — 5단계 문서화

| 항목 | 내용 |
|---|---|
| 모델 | `claude-haiku-4-5-20251001` |
| 의무 로드 | `05_document.md` + `review_report.md` + `plan.md` (슬림) + `plan_risks.md` |
| 산출물 (기본) | `./_harness/security_engineer/docs/...` |
| 산출물 (`--central`) | `~/.claude/_harness/security_engineer/docs/central/...` |

**두 가지 인자 형식**:

| 형식 | 의미 | 글로벌 템플릿 |
|---|---|---|
| `A` / `B` / `C` / `D` | 채널 출력 (내부기술문서 / 외부보안리포트 / Confluence / PPT) | (전용 템플릿 없음) |
| `ADR` / `PRD` / `ARCH` / `UI` | 표준 문서 종류 (v5.4 신규) | `~/.claude/_harness/security_engineer/docs/templates/{ADR,PRD,ARCHITECTURE,UI_GUIDE}.md` |

**예시 1 — 표준 ADR 생성**:

```bash
/harness:doc ADR JWT 알고리즘으로 HS256 채택 결정
# → ./_harness/security_engineer/docs/ADR/2026-04-30_JWT-알고리즘으로-HS256-채택-결정.md
```

**예시 2 — PRD 생성**:

```bash
/harness:doc PRD JWT 검증 모듈
# → ./_harness/security_engineer/docs/PRD/2026-04-30_JWT-검증-모듈.md
```

**예시 3 — 채널 출력 (외부 보안 리포트)**:

```bash
/harness:doc B
# 사용자에게 대상·청중 확인 후
# → ./_harness/security_engineer/docs/2026-04-30_B_*.md
```

**예시 4 — 다 프로젝트 산출물 중앙 수합**:

```bash
/harness:doc ARCH --central
# 사용자에게 어느 프로젝트들을 수합할지 확인 후
# → ~/.claude/_harness/security_engineer/docs/central/2026-04-30_<프로젝트명>_ARCH.md
```

---

### 4.8. `/teacher:ask` — 학부생 Q&A

| 항목 | 내용 |
|---|---|
| 모델 | `claude-sonnet-4-6` |
| 의무 로드 | `~/.claude/_harness/student/01_ask.md` |
| 산출물 | (대화만) |

```bash
/teacher:ask JWT의 exp 와 nbf 차이가 뭐예요?
```

```bash
/teacher:ask
# 인자 생략 시 사용자에게 질문 입력 요청
```

> 보안 작업 중간에 끼워 넣어도 격리 원칙으로 컨텍스트 오염 없음.

---

### 4.9. `/teacher:doc` — 학습 노트 정리

| 항목 | 내용 |
|---|---|
| 모델 | `claude-sonnet-4-6` |
| 산출물 | `./_harness/student/docs/[YYYY-MM-DD]_[주제].md` |

```bash
/teacher:doc 오늘 배운 JWT 시간 클레임 정리
# → ./_harness/student/docs/2026-04-30_JWT-시간-클레임.md
```

```bash
/teacher:doc
# 인자 생략 시 현재 대화 내용을 자동 정리
```

---

## 5. 자동 모델 전환 (model_switch)

`UserPromptSubmit` 훅이 매 프롬프트마다 매칭 패턴을 검사하여 `~/.claude/settings.json` 의 `model` 필드를 갱신한다.

### 5.1. 매핑 표

| 커맨드 패턴 | 모델 | 단가 비교 |
|---|---|---|
| `/harness:plan`, `/harness:critique` | `claude-opus-4-7` | Sonnet의 약 5배 |
| `/harness:confirm`, `/harness:execute`, `/harness:review`, `/harness:auto` | `claude-sonnet-4-6` | 기준 |
| `/harness:doc` | `claude-haiku-4-5-20251001` | Sonnet의 약 1/4 |
| `/teacher:ask`, `/teacher:doc` | `claude-sonnet-4-6` | 기준 |

### 5.2. 양 OS 동등 구현

| 파일 | 환경 | 등록 위치 |
|---|---|---|
| [hooks/model_switch.py](hooks/model_switch.py) | macOS/Linux | `~/.claude/settings.json` 의 `UserPromptSubmit` |
| [hooks/model_switch.ps1](hooks/model_switch.ps1) | Windows | `~/.claude/settings.json` 의 `UserPromptSubmit` |

> 신규 커맨드를 추가할 때는 **두 파일의 `MODEL_MAP` 을 동시에 갱신**해야 한다.

### 5.3. 모델 전환 시 캐시 무효화

> 모델이 바뀌면 프롬프트 캐시가 무효화된다. 동일 단계 내에서는 모델을 고정하고, 단계 묶음(예: `execute → review`)을 한 세션에서 처리하는 것을 권장한다.

---

## 6. Bash 안전 검사 (bash_safety)

`PreToolUse` 훅이 `Bash` 도구 호출 직전에 `hooks/lib/bash_patterns.json` 의 L4 패턴을 검사한다. 매칭 시 즉시 차단(`{"decision": "block", "reason": "..."}`).

### 6.1. 차단되는 패턴 (현행)

| 패턴 | 사유 |
|---|---|
| `rm -rf /`, `rm -rf ~`, `rm -rf $HOME`, `rm -rf ..`, `rm -rf *` | 루트·홈·상위·전체 삭제 |
| `rm -rf .` | 현재 디렉토리 통째 삭제 |
| `git push --force` / `-f` | 히스토리 덮어쓰기 |
| `git reset --hard` | untracked/staged 영구 손실 |
| `git clean -fdx` | untracked 파일 영구 삭제 |
| `DROP TABLE/DATABASE/SCHEMA` | DB 스키마 삭제 |
| `TRUNCATE TABLE` | 전체 데이터 삭제 |
| `DELETE FROM <table>` (WHERE 없음) | 전체 행 삭제 |
| `sudo rm -rf` | 권한 상승 후 강제 삭제 |
| `:(){ :\|:& };:` | fork bomb |
| `dd if=/dev/zero of=/dev/sd*` | 디스크 직접 쓰기 |
| `mkfs.* /dev/sd*` | 파일시스템 포맷 |
| `format C:` | Windows 드라이브 포맷 |
| `shutdown /s` / `-h` | 시스템 종료 |
| `chmod -R 777 /` 또는 `~` | 루트/홈 전체 777 |

### 6.2. 차단 메시지 예

```
[bash_safety L4 차단] 루트·홈·상위·전체 삭제 위험
- 매칭 패턴: rm\s+-rf\s+(/|~|...)
- 명령: rm -rf /tmp/foo/*
진행하려면 정말로 의도한 것인지 사용자와 확인 후 명령을 변형하거나 분리해서 실행하세요.
```

> **차단 = 거부**가 아니다. 사용자가 "정말로 의도한 명령" 임을 확인 후, 명령을 분리(`cd /tmp/foo && rm -rf .`)하거나 패턴을 회피해서 다시 시도할 수 있다.

### 6.3. 패턴 추가 방법

[hooks/lib/bash_patterns.json](hooks/lib/bash_patterns.json) 의 `L4_block` 배열에 추가:

```json
{
  "pattern": "kubectl\\s+delete\\s+ns\\s+\\w+",
  "reason": "namespace 통째 삭제"
}
```

> JSON escape 주의 — 백슬래시는 `\\\\` 로 두 번. 추가 후 분기 1회 점검.

---

## 7. 세션 종료 자동 검증 (stop_validate)

`Stop` 훅이 Claude 세션 종료 시 CWD 의 프로젝트 마커를 감지하여 적절한 검증 명령을 실행한다.

### 7.1. 검증 매트릭스

| 마커 파일 | 실행 명령 |
|---|---|
| `package.json` | `npm run lint --if-present` → `npm run build --if-present` → `npm test --if-present` (fail-fast) |
| `pyproject.toml` | `pytest -q` |
| `Cargo.toml` | `cargo check --quiet` → 통과 시 `cargo test --quiet` |
| `go.mod` | `go build ./...` → 통과 시 `go test ./...` |
| (마커 없음) | skip |

### 7.2. 핵심 동작

- **변경 없으면 skip**: `git diff --quiet` 가 0 (변경 없음) 이면 즉시 종료. (비-Git 레포는 항상 실행.)
- **타임아웃**: 명령당 120초.
- **로그 폭증 방지**: 실패 시 마지막 20줄만 stderr 로 출력.
- **차단하지 않음**: 검증 실패해도 세션은 정상 종료. 정보 전달만.

### 7.3. 출력 예

```
[stop_validate]
  [OK ] npm lint (exit 0)
  [FAIL] npm test (exit 1)
  --- output (last 20 lines) ---
    FAIL  src/jwt.test.ts
     × should reject expired tokens
       Expected: 401, Received: 200
```

---

## 8. Karpathy 4원칙

`~/.claude/rules/common/karpathy_guidelines.md` 가 `/harness:execute` 와 `/harness:auto` 의 **의무 로드** 파일이다.

| # | 원칙 | 한 줄 요약 |
|---|---|---|
| 1 | **Think Before Coding** | 가정을 표면화. 모호하면 멈추고 사용자에게 확인. |
| 2 | **Simplicity First** | 요청 이상 작성 금지. 추상화·유연성·미래 대비 코드 X. |
| 3 | **Surgical Changes** | `plan/{N}.md` 에 명시된 파일만 수정. 인접 코드 개선 금지. |
| 4 | **Goal-Driven Execution** | 모호한 목표 → 검증 명령으로 변환. 통과까지 자율 루프 가능. |

### 8.1. plan 단계 강제 항목

- **Assumptions 표** — 모든 가정을 행으로 나열, 상태(`확인 필요` / `확정`) 명시.
- **Verification 섹션** — 단계마다 검증 명령 + 통과 조건 + 부정 케이스.

### 8.2. critique 단계 자동 검출

- 과추상화 (1회용 코드에 인터페이스 분리 등)
- 미확정 가정 (확인 필요 상태로 남은 항목)
- 누락 Verification (단계에 검증 명령 없음)
- 범위 일탈 (Surgical 위반 — 요청 외 파일 변경 의도)

### 8.3. execute / auto 단계 게이트

- Assumptions 의 "확인 필요" 항목이 있으면 STOP
- Verification 섹션이 없으면 STOP
- 위 둘이 모두 통과해야 코드 작성 시작

---

## 9. 표준 문서 템플릿 (ADR/PRD/ARCH/UI)

`/harness:doc {ADR|PRD|ARCH|UI} <제목>` 으로 호출하면 글로벌 템플릿을 기반으로 작성한다.

### 9.1. 템플릿 위치 (정의)

| 종류 | 템플릿 |
|---|---|
| `ADR` (Architecture Decision Record) | [_harness/security_engineer/docs/templates/ADR.md](_harness/security_engineer/docs/templates/ADR.md) |
| `PRD` (Product Requirements Document) | [_harness/security_engineer/docs/templates/PRD.md](_harness/security_engineer/docs/templates/PRD.md) |
| `ARCH` (Architecture Document) | [_harness/security_engineer/docs/templates/ARCHITECTURE.md](_harness/security_engineer/docs/templates/ARCHITECTURE.md) |
| `UI` (UI/CLI/Output Guide) | [_harness/security_engineer/docs/templates/UI_GUIDE.md](_harness/security_engineer/docs/templates/UI_GUIDE.md) |

### 9.2. 보안 엔지니어 특화 항목 (모든 템플릿 공통)

- **Assumptions** (Karpathy 1원칙) — 가정 표
- **위협 모델링 / 보안 고려사항** — 인증·시크릿·공급망·로깅
- **Verification** (Karpathy 4원칙) — 검증 명령·통과 조건·부정 케이스

### 9.3. 산출물 위치 (프로젝트 로컬)

```
./_harness/security_engineer/docs/
├── ADR/2026-04-30_<제목>.md
├── PRD/2026-04-30_<기능명>.md
├── ARCH/2026-04-30_<시스템명>.md
└── UI/2026-04-30_<제품명>.md
```

`--central` 시: `~/.claude/_harness/security_engineer/docs/central/` 에 `[YYYY-MM-DD]_[프로젝트명]_[유형].md` 형식으로 저장.

---

## 10. 토큰 비용 가드

| 메커니즘 | 적용 위치 | 효과 |
|---|---|---|
| `plan.md` 슬라이싱 | `/harness:execute` 가 `plan/{N}.md` 1개만 로드 | 단계당 입력 5~10K 절감 |
| 리스크 표 분리 | `plan_risks.md` 는 review/doc 시에만 로드 | 비판/실행 라운드당 1~2K 절감 |
| `--diff` 비판 | 직전 라운드 git diff 만 입력 | N회 라운드 = N배 폭증 회피 |
| `review_report` 압축 | Haiku 50줄 미만 + 원본 archive | doc 단계 누적 70% 절감 |
| 의무 로드 표 | 단계당 1~2개만 자동 로드 | 단계당 8~12K 고정 비용 제거 |
| `/harness:auto` Verification 루프 | 검증 통과까지 자율 반복 | 사용자 확인 라운드 트립 감소 — 라운드당 5~15K 절감 |
| Karpathy Assumptions 사전 확정 | `/harness:plan` 단계 가정 표면화 | 후반 재작업으로 인한 plan→execute 재진입 회피 |

---

## 11. 권한 / 보안 정책

전체 정의: [_harness/permissions.md](_harness/permissions.md)

### 11.1. 단계별 허용 도구 (요약)

| 단계 | 허용 | 금지 |
|---|---|---|
| plan | Read, WebSearch, WebFetch, TodoWrite | Write/Edit, Bash, 외부 API |
| critique | Read, WebSearch, WebFetch | Write/Edit, Bash |
| execute | Read, Write, Edit, Bash, TodoWrite | `plan.md` 임의 덮어쓰기 |
| review | Read, WebSearch | Edit/Write, Bash |
| document | Read, Write | Edit (코드 수정), Bash |
| teacher:ask | Read, WebSearch, WebFetch | 파일 쓰기, Bash |
| teacher:doc | Read, Write | Bash |

### 11.2. 보안 정책 결정 사항 (현행)

| 정책 | 결정 | 근거 | 재검토 |
|---|---|---|---|
| Python 경로 (macOS/Linux) | `/usr/bin/python3` 고정 (3.9.6) | 가상환경/brew 혼용 회피 | Python 메이저 업그레이드 |
| 훅 런타임 (Windows) | PowerShell 5.1 + `.ps1` 훅 | Python 미설치 환경 대응 | Python 도입 시 `.py` 로 통합 |
| GPG signed commit | **미도입** | 초기 운영 부담 최소화 | 7일 운영 무사고 후 |
| `.env` 위치 | `~/.claude/_harness/projects/{프로젝트명}/.env` (Git 강제 제외) | 프로젝트 격리 + 시크릿 중앙 보관 | 변경 없음 |
| L4 Bash 차단 | 즉시 차단 + 사유 표시, 우회는 사용자 명시 변형 | 명백한 파괴 명령 | 분기 1회 패턴 점검 |

### 11.3. 정기 점검 체크리스트

- [ ] **월간**: `permissions.md`, `model_switch.py`/`.ps1` 매핑 검토
- [ ] **분기**: `bash_patterns.json` 누락 패턴 검토, `.env.example` 슬롯 정합성
- [ ] **단계 종료 시**: `plan_risks.md` 재평가
- [ ] **신규 커맨드 추가 시**: `model_switch.py` ↔ `.ps1` 동기화 확인

---

## 12. 설치 — 단일 명령

### 12.1. macOS / Linux

```bash
git clone <harness-repo> harness
cd harness
./scripts/setup.sh
```

`setup.sh` 가 처리하는 것:
1. `~/.claude/{commands, hooks}` 디렉토리 보장
2. 다음 5개 디렉토리 symlink 생성:
   - `~/.claude/commands/harness` → `<harness>/commands/harness`
   - `~/.claude/commands/teacher` → `<harness>/commands/teacher`
   - `~/.claude/_harness` → `<harness>/_harness`
   - `~/.claude/rules` → `<harness>/rules`
   - `~/.claude/hooks/lib` → `<harness>/hooks/lib`
3. 다음 4개 파일 symlink 생성:
   - `~/.claude/CLAUDE.md` → `<harness>/CLAUDE.md`
   - `~/.claude/hooks/{model_switch,bash_safety,stop_validate}.py`
4. `~/.claude/settings.json` 에 3개 훅 자동 등록 (idempotent):
   - `UserPromptSubmit` → `model_switch.py`
   - `PreToolUse(Bash)` → `bash_safety.py`
   - `Stop` → `stop_validate.py`
5. 검증 단계 — 9개 핵심 경로 존재 확인

### 12.2. Windows

```powershell
git clone <harness-repo> harness
cd harness
powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
```

`setup.ps1` 가 처리하는 것:
1. 디렉토리(`commands/harness`, `commands/teacher`, `_harness`, `rules`, `hooks/lib`) → **junction**
2. 파일(`CLAUDE.md`, `hooks/*.ps1`) → **hardlink** (같은 볼륨 필수)
3. `settings.json` 자동 작성/병합 — PowerShell 5.1 의 `ConvertTo-Json` 한계를 회피하기 위해 정적 템플릿 방식 사용
4. 9개 핵심 경로 검증

### 12.3. 설치 검증 (양 OS 공통)

```bash
# 새 Claude Code 세션 열기
/harness:plan 테스트 프로젝트
# settings.json 의 model 이 claude-opus-4-7 로 자동 전환되는지 확인
```

```bash
ls ~/.claude/commands/harness/
# plan.md critique.md confirm.md execute.md auto.md review.md doc.md
```

### 12.4. 링크 끊김 시

| 경우 | 조치 |
|---|---|
| macOS/Linux: 레포를 다른 경로로 이동 | `setup.sh` 재실행 |
| Windows: 디렉토리 이름 변경 | junction 끊김 → `setup.ps1` 재실행 |
| Windows: 파일 삭제 후 재생성 | hardlink 끊김 → `setup.ps1` 재실행 |

---

## 13. End-to-End 시나리오

### 13.1. 표준 보안 엔지니어 흐름 (수동)

```bash
# 작업 디렉토리로 이동 (← 그 자리에 ./_harness/ 가 생성됨)
cd ~/projects/my-api-gateway

# 1) 계획
/harness:plan JWT 검증 모듈 개발

# 2) 비판 루프
/harness:critique
/harness:plan 비판 반영
/harness:critique --diff   # 토큰 절약 모드

# 3) 확정
/harness:confirm

# 4) 단계별 실행
/harness:execute 1   # 토큰 파서
/harness:execute 2   # 서명 검증
/harness:execute     # 자동으로 첫 미완료 단계 (=3)

# 5) 종합 검토
/harness:review

# 6) 문서화 — 표준 템플릿 사용
/harness:doc PRD JWT 검증 모듈
/harness:doc ADR HS256 알고리즘 채택
/harness:doc ARCH 게이트웨이 인증 흐름
```

### 13.2. 자율 실행 흐름 (대규모 작업)

```bash
cd ~/projects/scanner-cli

/harness:plan 사내 취약점 스캐너 CLI v1
/harness:critique
/harness:confirm

# 1단계만 수동 검증
/harness:execute 1

# 2~10단계 자율 진행 (Verification 통과까지 자동 수정 시도)
/harness:auto 2..10

# 결과 확인 — auto_state.json 에 단계별 상태 저장됨
cat ./_harness/security_engineer/auto_state.json

# blocked 단계가 있으면 사용자가 개입
/harness:execute 5   # 수동으로 재시도

# 검토 + 문서화
/harness:review
/harness:doc B   # 외부 보안 리포트
```

### 13.3. 학부생 모드 끼워넣기

```bash
# 보안 작업 중간에 개념 질문이 생겼을 때
/teacher:ask JWT 의 nbf 클레임은 언제 쓰나요?

# 답변 후 정리
/teacher:doc JWT 시간 클레임 (exp/nbf/iat)
# → ./_harness/student/docs/2026-04-30_JWT-시간-클레임.md

# 다시 보안 작업으로 복귀 (격리 원칙으로 컨텍스트 오염 없음)
/harness:execute 3
```

### 13.4. 다 프로젝트 산출물 중앙 수합

```bash
# 프로젝트 A
cd ~/projects/api-gateway && /harness:doc ARCH 게이트웨이 아키텍처

# 프로젝트 B
cd ~/projects/scanner-cli && /harness:doc ARCH 스캐너 아키텍처

# 분기 보고용으로 한 곳에 모으기
cd ~/projects/api-gateway   # 어느 프로젝트든 OK
/harness:doc ARCH --central
# 사용자에게 어느 프로젝트들을 수합할지 확인 후
# → ~/.claude/_harness/security_engineer/docs/central/2026-04-30_*.md 모음
```

---

## 14. 참고·트러블슈팅·변경 이력

### 14.1. 사용자가 자주 참조하는 파일

| 우선순위 | 파일 | 종류 | 언제 |
|---|---|---|---|
| ★★★ | [CLAUDE.md](CLAUDE.md) | 글로벌 정의 | 모든 세션 자동 로드 |
| ★★★ | `./_harness/security_engineer/plan.md` | 프로젝트 산출물 | 모든 단계 — 헤더+로드맵 확인 |
| ★★★ | `./_harness/security_engineer/plan/{N}.md` | 프로젝트 산출물 | 진입할 단계 본문 |
| ★★ | `./_harness/history.md` | 프로젝트 산출물 | 세션 재개 시 가장 먼저 |
| ★★ | [_harness/permissions.md](_harness/permissions.md) | 글로벌 정의 | 권한·정책 변경 시 |
| ★★ | [rules/common/karpathy_guidelines.md](rules/common/karpathy_guidelines.md) | 글로벌 정의 | execute/auto 의무 로드 |
| ★★ | `./_harness/security_engineer/plan_risks.md` | 프로젝트 산출물 | review/doc 또는 의사결정 시 |
| ★★ | `./_harness/security_engineer/auto_state.json` | 프로젝트 산출물 | `/harness:auto` 후 진행 상태 |
| ★ | [_harness/security_engineer/execute_library.md](_harness/security_engineer/execute_library.md) | 글로벌 정의 | 외부 라이브러리·MCP 사용 시 |
| ★ | [hooks/lib/bash_patterns.json](hooks/lib/bash_patterns.json) | 글로벌 정의 | 차단 패턴 추가 시 |
| ★ | [.claude-plugin/plugin.json](.claude-plugin/plugin.json) | 글로벌 정의 | 플러그인 메타데이터 |

### 14.2. 자주 묻는 트러블슈팅

| 증상 | 원인 | 조치 |
|---|---|---|
| 모델이 자동 전환 안 됨 | `~/.claude/settings.json` 에 `UserPromptSubmit` 훅 미등록 | `setup.sh`/`setup.ps1` 재실행 |
| 슬래시 커맨드가 인식 안 됨 | `~/.claude/commands/` link 끊김 | setup 스크립트 재실행 |
| Windows 에서 hardlink 실패 | 다른 볼륨 (예: C: ↔ D:) | 같은 볼륨으로 레포 이동 후 재실행 |
| Bash 명령이 차단됨 | L4 패턴 매칭 (`bash_patterns.json`) | 명령 변형/분리 또는 패턴 확인 |
| `/harness:auto` 가 STOP | Assumption 미확정 / Verification 누락 / 3회 실패 | `auto_state.json` 의 `last_error` 확인 → 수동 처리 |
| `stop_validate` 가 실패 표시 | 프로젝트 빌드/테스트 실제 실패 | stderr 출력 마지막 20줄 참조 |
| 모델 전환 후 캐시 무효화로 느려짐 | 단계 묶음 미준수 | execute → review 같은 한 세션에서 처리 |

### 14.3. 도움말 / 변경 이력

- 글로벌 하네스 변경 로그: [_harness/history.md](_harness/history.md)
- 프로젝트별 진행 이력: 각 프로젝트의 `./_harness/history.md`
- 글로벌 권한·정책: [_harness/permissions.md](_harness/permissions.md)
- 실행 라이브러리 카탈로그: [_harness/security_engineer/execute_library.md](_harness/security_engineer/execute_library.md)
- Karpathy 4원칙 정의: [rules/common/karpathy_guidelines.md](rules/common/karpathy_guidelines.md)
- 플러그인 메타데이터: [.claude-plugin/plugin.json](.claude-plugin/plugin.json)

### 14.4. 변경 이력 (주요)

| 버전 | 날짜 | 주요 변경 |
|---|---|---|
| **v5.4** | 2026-04-30 | `/harness:auto` 자율 실행 루프, 표준 문서 템플릿 (ADR/PRD/ARCH/UI), `bash_safety` 훅, `stop_validate` 훅, 모든 훅 양 OS 동등 구현 |
| v5.3 | 2026-04-30 | OS-비의존 일원화 — 모든 절대경로 `~/.claude/...` 로 통일, `setup.{sh,ps1}` 단일 명령 |
| v5.2 | 2026-04-29 | Karpathy 4원칙 통합 (rules/common/karpathy_guidelines.md), plan 템플릿 Assumptions·Verification 강제, critique Karpathy 위반 검출, `.claude-plugin/plugin.json` 패키징 |
| v5.2 | 2026-04-27 | Windows 환경 지원 (PowerShell 훅, junction/hardlink 셋업) |
| v5.1 | 2026-04-26 | 정의(글로벌) ↔ 산출물(프로젝트 로컬) 분리 규칙 |
| v5.0 | — | 토큰 비용 가드 (슬라이싱·diff·skip) 도입 |

---

## 15. 오픈소스 참고

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 워크플로/구조 영감
- [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — LLM 코딩 4원칙을 `rules/common/karpathy_guidelines.md` 로 통합 (v5.2)
- [jha0313/harness_framework](https://github.com/jha0313/harness_framework) — `/harness:auto` 자율 루프 영감 (v5.4)

| 요구사항 | everything-claude-code | karpathy-skills | 이 레포 |
|---|---|---|---|
| `history.md` 프로젝트 이력 추적 | ❌ | ❌ | ✅ |
| 기본 언어 한국어 | ❌ | ❌ | ✅ |
| 페르소나 분리 | ❌ | ❌ | ✅ (보안엔지니어/학부생) |
| 계획 → 비판 루프 | ❌ | ❌ | ✅ (`--diff` 옵션) |
| Karpathy 4원칙 통합 | ❌ | ✅ (단일 skill) | ✅ (execute 의무 로드, critique 검출, plan 템플릿 강제) |
| 자율 실행 루프 | ❌ | ❌ | ✅ (`/harness:auto` v5.4) |
| 표준 문서 템플릿 | ❌ | ❌ | ✅ (ADR/PRD/ARCH/UI v5.4) |
| Bash 안전 차단 | ❌ | ❌ | ✅ (`bash_safety` 훅) |
| 세션 종료 자동 검증 | ❌ | ❌ | ✅ (`stop_validate` 훅) |
| 훅 기반 모델 자동 전환 | ❌ | ❌ | ✅ (Python + PowerShell) |
| 토큰 비용 가드 (슬라이싱/diff/skip) | ❌ | ❌ | ✅ (v5.0~5.4 누적) |
| Windows 네이티브 지원 | ❌ | ❌ | ✅ (PowerShell 훅 + junction/hardlink) |
| Plugin 패키징 | ❌ | ✅ (skills) | ✅ (commands+hooks+rules) |
