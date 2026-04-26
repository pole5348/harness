# 단계별 MCP / Skills / 권한 관리

> 각 에이전트가 사용하는 MCP, Skills, 권한을 한 곳에서 관리한다.
> 원칙: **필요한 만큼만** 권한을 부여한다. 단계가 끝나면 해당 권한은 해제한다.

---

## 보안 엔지니어 페르소나

### 1단계 — 계획 (plan)

| 항목 | 내용 |
|---|---|
| 모델 | claude-opus-4-6 이상 |
| 허용 도구 | Read, WebSearch, WebFetch, TodoWrite |
| MCP | 필요 없음 (리서치 단계) |
| Skills | `Plan` subagent |
| 금지 | 파일 쓰기(Write/Edit), 코드 실행(Bash), 외부 API 호출 |
| 산출물 | `_harness/security_engineer/plan.md` (최종 확정 시) |

### 2단계 — 비판 (critique)

| 항목 | 내용 |
|---|---|
| 모델 | claude-opus-4-6 이상 |
| 허용 도구 | Read, WebSearch, WebFetch |
| MCP | 필요 없음 |
| Skills | 없음 (독립 분석) |
| 금지 | 파일 쓰기(Write/Edit), 코드 실행(Bash) |
| 산출물 | `_harness/history.md`에 비판 이력 추가 |
| 주의 | 이전 비판 내용을 참고하지 않는다 (격리 원칙) |

### 3단계 — 실행 (execute)

| 항목 | 내용 |
|---|---|
| 모델 | claude-sonnet-4-6 |
| 허용 도구 | Read, Write, Edit, Bash, TodoWrite |
| MCP | 프로젝트별 상이 — `execute_library.md` 참고 |
| Skills | 프로젝트별 상이 — `execute_library.md` 참고 |
| 금지 | 계획 수정, `plan.md` 덮어쓰기 |
| 산출물 | 실행 결과물, `sbom_report.md`, `_harness/history.md` 업데이트 |

### 4단계 — 검토 (review)

| 항목 | 내용 |
|---|---|
| 모델 | claude-sonnet-4-6 또는 claude-haiku-4-5 |
| 허용 도구 | Read, WebSearch |
| MCP | 필요 없음 |
| Skills | `security-review`, `review` (필요 시) |
| 금지 | 코드 수정(Edit/Write), Bash 실행 |
| 산출물 | `_harness/security_engineer/review_report.md` |

### 5단계 — 문서화 (document)

| 항목 | 내용 |
|---|---|
| 모델 | claude-haiku-4-5 또는 claude-sonnet-4-6 |
| 허용 도구 | Read, Write |
| MCP | Confluence MCP (연결 시), 디자인 툴 MCP (연결 시) |
| Skills | 없음 |
| 금지 | 코드 수정, Bash 실행 |
| 산출물 | 정형화된 문서 파일 |

---

## 학부생 페르소나

### 1단계 — 질문 (ask)

| 항목 | 내용 |
|---|---|
| 모델 | claude-sonnet-4-6 또는 claude-haiku-4-5 |
| 허용 도구 | Read, WebSearch, WebFetch |
| MCP | 필요 없음 |
| Skills | 없음 |
| 금지 | 파일 쓰기, Bash 실행 |
| 산출물 | 답변 (도표/구성도 포함) |

### 2단계 — 문서화 (document)

| 항목 | 내용 |
|---|---|
| 모델 | claude-sonnet-4-6 또는 claude-haiku-4-5 |
| 허용 도구 | Read, Write |
| MCP | Confluence MCP, 티스토리 MCP (연결 시) |
| Skills | 없음 |
| 금지 | 코드 실행(Bash) |
| 산출물 | `_harness/student/` 하위 학습 문서 |

---

## 보안 정책 결정 사항

### GPG Signed Commit — 미도입 결정 (1단계 확정)

| 항목 | 내용 |
|---|---|
| 결정 | GPG 서명 커밋 **미도입** (운영 안정화 후 재검토) |
| 현재 보호 수단 | `manifest_root.sha256` + `chmod 600` |
| 재검토 시점 | 7일 운영 무사고 후 (10단계 이후) |
| 리스크 | `chmod 600` 단독 보호 한계 — 사용자 권한 RCE 시 무력화 가능 |
| 근거 | 초기 운영 부담 최소화. 안정화 전 GPG 설정 복잡도가 이점 초과 |

### Python 경로 — /usr/bin/python3 고정 (1단계 확정)

| 항목 | 내용 |
|---|---|
| 경로 | `/usr/bin/python3` (Python 3.9.6, macOS 시스템) |
| 적용 범위 | `settings.json` 훅 명령, 모든 `hooks/*.py` shebang |
| 변경 시 | 이 파일 + `settings.json` + 각 훅 shebang 동시 갱신 |

### 코딩 규칙 — history/status 직접 쓰기 금지 (3단계 구현 후 강제)

> `hooks/`, `commands/` 내에서 `_harness/history*.md` 또는 `_harness/status.md`에 직접 `open()+write()` 사용 금지.
> 3단계 `hooks/lib/safe_write.py` 구현 후 단일 진입점으로만 기록한다. pre-commit으로 강제.

---

## MCP 연결 현황

| MCP 서버 | 용도 | 연결 여부 | 관련 단계 |
|---|---|---|---|
| Confluence MCP | 사내 위키 업로드 | 미연결 | 보안엔지니어 5단계, 학부생 2단계 |
| 티스토리 MCP | 블로그 포스팅 | 미연결 | 학부생 2단계 |
| 디자인 MCP | PPT/디자인 생성 | 미연결 | 보안엔지니어 5단계 |

> MCP 서버 연결 시 이 파일을 업데이트하고 `history.md`에 기록한다.
