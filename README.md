# Harness Engineering

> Claude Code 하네스 엔지니어링 기반의 프롬프트 관리 레포입니다.
> CLAUDE.md 변경 이력을 Git으로 추적하고, 페르소나별 에이전트 워크플로를 정의합니다.

---

## 오픈소스 참고

[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 를 참고하여 커스텀 구성했습니다.

### 오픈소스 vs 커스텀 비교

| 요구사항 | 오픈소스 | 이 레포 |
|---|---|---|
| `history.md` 프로젝트 이력 추적 | ❌ | ✅ |
| 기본 언어 한국어 | ❌ (영어 전용) | ✅ |
| 페르소나 분리 (보안엔지니어 / 학부생) | ❌ | ✅ |
| 계획 에이전트 | △ (planner, 범용) | ✅ (보안 특화, Opus) |
| 비판 에이전트 + 루프 | ❌ | ✅ |
| 실행 에이전트 + SBOM | △ (SBOM 없음) | ✅ |
| 검토 에이전트 (종합) | △ (부분적) | ✅ |
| 문서화 에이전트 | ❌ | ✅ |
| 학부생 질문/문서화 에이전트 | ❌ | ✅ |
| 단계별 MCP/Skills/권한 관리 md | ❌ | ✅ |
| CLAUDE.md 심볼릭 링크 설정 | ❌ | ✅ |
| 훅 기반 모델 자동 전환 | ❌ | ✅ |
| 시크릿 마스킹 단일 진입점 | ❌ | ✅ (3단계 구현 예정) |
| 훅 신뢰 루트 (manifest 검증) | ❌ | ✅ (2단계 구현 예정) |
| Continuous Learning + `/se:note` | ❌ | ✅ (9단계 구현 예정) |

---

## 디렉토리 구조

```
harness/
├── CLAUDE.md                          # 글로벌 지침 (↔ ~/.claude/CLAUDE.md 심볼릭 링크)
├── README.md
├── .env.example                       # 시크릿 슬롯 템플릿 (값 없음, Git 추적)
├── .gitignore
├── hooks/                             # UserPromptSubmit 등 훅 스크립트
│   └── model_switch.py                # 커맨드 감지 → settings.json 모델 자동 전환
├── commands/
│   ├── se/                            # 보안 엔지니어 슬래시 커맨드
│   └── teacher/                       # 학부생 슬래시 커맨드
└── _harness/
    ├── history.md                     # 전체 프로젝트 이력
    ├── permissions.md                 # 단계별 MCP/Skills/권한 + 보안 정책 결정
    ├── projects/                      # 프로젝트별 .env 저장 위치 (Git 제외)
    │   └── {프로젝트명}/.env
    ├── security_engineer/             # 보안 엔지니어 페르소나
    │   ├── 01_plan.md                 # 1단계: 계획 에이전트
    │   ├── 02_critique.md             # 2단계: 비판 에이전트
    │   ├── 03_execute.md              # 3단계: 실행 에이전트
    │   ├── 04_review.md               # 4단계: 검토 에이전트
    │   ├── 05_document.md             # 5단계: 문서화 에이전트
    │   ├── execute_library.md         # 실행 단계 MCP/Skills 라이브러리
    │   ├── plan.md                    # (프로젝트 시작 시 생성) 최종 확정 계획
    │   ├── sbom_report.md             # (실행 시 생성) SBOM 리포트
    │   ├── review_report.md           # (검토 시 생성) 종합 검토 리포트
    │   └── docs/                      # (문서화 시 생성) 배포용 문서들
    └── student/                       # 학부생 페르소나
        ├── 01_ask.md                  # 1단계: 질문 에이전트
        ├── 02_document.md             # 2단계: 문서화 에이전트
        └── docs/                      # (문서화 시 생성) 학습 문서들
```

---

## 심볼릭 링크 설정

```bash
# 이미 설정 완료 — 아래는 재설정이 필요할 때 사용
ln -s /Users/pole/scripts/harness/harness/CLAUDE.md ~/.claude/CLAUDE.md
ln -s /Users/pole/scripts/harness/harness/commands/se  ~/.claude/commands/se
ln -s /Users/pole/scripts/harness/harness/commands/teacher  ~/.claude/commands/teacher
ln -s /Users/pole/scripts/harness/harness/hooks/model_switch.py  ~/.claude/hooks/model_switch.py
```

확인:
```bash
ls -la ~/.claude/CLAUDE.md
# ~/.claude/CLAUDE.md -> /Users/pole/scripts/harness/harness/CLAUDE.md
```

---

## 슬래시 커맨드

`~/.claude/commands/` 에 등록된 글로벌 커맨드. Claude Code 어디서든 사용 가능.
**커맨드 실행 시 모델이 자동 전환됩니다** — 수동 `/model` 명령 불필요.

### 보안 엔지니어 워크플로

```
/se:plan 취약점 스캐너 개발          ← Opus 자동 전환, 계획 수립
/se:critique                         ← Opus 유지, 계획 비판 (반복 가능)
/se:plan 수정사항 반영하여 재계획     ← 계획 수정
/se:critique                         ← 재비판
/se:confirm                          ← Sonnet 자동 전환, plan.md 확정 저장
/se:execute 1단계 스캐너 코어        ← Sonnet 유지, 실행
/se:review                           ← Sonnet 유지, 종합 검토
/se:doc B                            ← Haiku 자동 전환, 문서화 (B=외부보안리포트)
```

### 보조 커맨드

```
/se:backup                           ← Sonnet, 진행 상태 status.md 스냅샷 저장
/se:summary                          ← Sonnet, 세션 요약 (수동 트리거 전용)
/se:note decision <내용>             ← 결론 마킹 → decisions_index.md 기록
/se:note rationale <내용>            ← 판단 근거 마킹
/se:note tradeoff <내용>             ← 트레이드오프 마킹
/se:note concern <내용>              ← 우려 사항 마킹
```

### Continuous Learning 커맨드

```
/se:learn sonnet                     ← Sonnet 전환 + quarantine 검토·수락·거부
/se:learn opus                       ← Opus 전환 + quarantine 검토
/se:learn rollback <commit-hash>     ← 이전 자동 반영 롤백
/se:learn audit                      ← 최근 1주일 자동 반영 점검
/se:learn cleanup                    ← 30일 만료 quarantine 아카이브 (수동)
```

> `/se:learn` 인자 누락 시 모델 전환이 차단되고 사용법 안내가 표시됩니다.

### 학부생 Q&A

```
/teacher:ask JWT 토큰이 뭐야?        ← Sonnet 자동 전환
/teacher:doc 오늘 배운 JWT 내용 정리
```

> 보안 엔지니어 작업 중 갑자기 궁금한 게 생기면 `/teacher:ask` 로 바로 전환

---

## 모델 할당

| 에이전트 | 모델 |
|---|---|
| 계획, 비판 | claude-opus-4-7 |
| 실행, 검토, 확정, 보조 커맨드 | claude-sonnet-4-6 |
| 문서화 (보안엔지니어) | claude-haiku-4-5-20251001 |
| 질문, 문서화 (학부생) | claude-sonnet-4-6 |

---

## 시크릿 관리 정책

- 실제 시크릿은 `_harness/projects/{프로젝트명}/.env` 에 저장 — **Git 제외 강제**
- `.env.example` 에 슬롯만 정의 (값 없음) — Git 추적 허용
- `hooks/`, `commands/` 내에서 history/status 파일에 직접 `open()+write()` 금지
  - 3단계 구현 후 `hooks/lib/safe_write.py` 단일 진입점만 허용 (pre-commit 강제)

---

## 주요 파일 가이드

| 파일 | 언제 참고하는가 |
|---|---|
| `CLAUDE.md` | 항상 — 글로벌 지침 |
| `_harness/history.md` | 세션 재개 시 가장 먼저 확인 |
| `_harness/permissions.md` | 새 단계 시작 전, MCP/권한/보안 정책 확인 |
| `_harness/security_engineer/execute_library.md` | 실행 단계 전 필요 도구 확인 |
| `_harness/security_engineer/plan.md` | 최종 확정 계획 (실행 단계 기준) |
| `.env.example` | 새 프로젝트 시크릿 슬롯 추가 시 참고 |
