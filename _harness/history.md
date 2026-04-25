# 프로젝트 이력 (History)

> 이 파일은 모든 프로젝트의 진행 이력을 시간순으로 기록한다.
> 세션이 중단됐다가 재개될 때 이 파일을 먼저 참고하여 컨텍스트를 복원한다.

## 기록 형식

```markdown
### [날짜] [페르소나] [단계] — [작업 제목]
- **진행 사항**: 
- **이슈**: 
- **조치**: 
- **미결 사항 / 개선 포인트**: 
```

---

## 2026-04-25 — Obsidian (Claudian) 연동 (obsidian 브랜치)

- **진행 사항**:
  - 볼트 경로 = 하네스 레포 (`/Users/pole/scripts/harness/harness`) — 파일 이동 불필요
  - `.claude/CLAUDE.md` → `../CLAUDE.md` 심볼릭 링크 생성 (Claudian이 로드)
  - `.claude/commands` → `../commands` 심볼릭 링크 생성 (커맨드 볼트 레벨 등록)
  - `.claudian/` 디렉토리 생성 + `.gitignore` (세션 파일 추적 제외)
  - CLAUDE.md에 Obsidian 전용 사용 지침 섹션 추가
  - README에 Obsidian 설정 가이드 추가
- **역할 분담 결정**:
  - CLI/VSCode: SE 실행 워크플로 (`/se:plan` ~ `/se:review`)
  - Obsidian: 학습 노트 (`/teacher:ask`), 문서 마무리 (`/se:doc`), `_harness/` 파일 열람
- **미결 사항**:
  - Claudian 플러그인 실제 설치는 사용자가 Obsidian 앱에서 수동 진행 필요
  - `UserPromptSubmit` 훅이 Claudian 세션에서도 동작하는지 실사용 후 검증 필요

---

## 2026-04-25 — 슬래시 커맨드 네임스페이스 전환 + 모델 자동 전환 훅 구현

- **진행 사항**:
  - 커맨드 형식을 `/se:plan`, `/teacher:ask` 네임스페이스 방식으로 변경
  - `~/.claude/commands/se/`, `~/.claude/commands/teacher/` 서브디렉토리 구조로 재구성
  - `UserPromptSubmit` 훅(`hooks/model_switch.py`) 구현 — 커맨드 감지 시 `settings.json` 모델 자동 전환
  - 커맨드 소스를 하네스 레포에 두고 `~/.claude/commands/`에 심볼릭 링크 연결
  - `hooks/model_switch.py` 도 하네스 레포에서 관리, `~/.claude/hooks/`에 심볼릭 링크
- **모델 매핑**:
  - `/se:plan`, `/se:critique` → `claude-opus-4-7`
  - `/se:confirm`, `/se:execute`, `/se:review`, `/teacher:*` → `claude-sonnet-4-6`
  - `/se:doc` → `claude-haiku-4-5-20251001`
- **이슈**: `model` 프론트매터가 커맨드 파일에서 동작 여부 불확실 → 훅으로 강제 전환 추가
- **미결 사항**: Confluence, 티스토리, 디자인 MCP 연결 필요

---

## 2026-04-25 — 태그 방식 → 슬래시 커맨드 방식으로 전환

- **진행 사항**:
  - `[SE]`, `[학부생]` 태그 기반 활성화 방식을 슬래시 커맨드로 전환
  - `~/.claude/commands/` 에 8개 글로벌 커맨드 생성
    - 보안엔지니어: `/se-plan`, `/se-critique`, `/confirm-plan`, `/se-execute`, `/se-review`, `/se-doc`
    - 학부생: `/stu-ask`, `/stu-doc`
  - CLAUDE.md, README.md 반영 완료
- **이슈**: 태그 방식은 타이핑이 번거롭고 오타 가능성 있음
- **조치**: 슬래시 커맨드로 자동완성 지원 및 인자 전달 구조화
- **미결 사항**: 각 커맨드 실행 전 모델 전환(`/model`)은 여전히 수동

---

## 2026-04-25 — 하네스 환경 초기 세팅

- **진행 사항**: 
  - 하네스 엔지니어링 레포 초기 구조 설계 및 파일 생성
  - 오픈소스(affaan-m/everything-claude-code) 분석 및 요구사항 비교
  - CLAUDE.md 생성 및 `~/.claude/CLAUDE.md` 심볼릭 링크 설정
  - `_harness/` 디렉토리 전체 구조 생성 (보안엔지니어 5단계, 학부생 2단계)
- **이슈**: 
  - 오픈소스에 한국어 지원, 페르소나 분리, history.md, SBOM, 계획-비판 루프 기능 없음 → 전부 직접 구현
- **조치**: 
  - 요구사항 기반 커스텀 하네스 구조 설계 및 완전 구현
- **미결 사항 / 개선 포인트**: 
  - Confluence, 티스토리, 디자인 MCP 연결 필요 (현재 미연결)
  - 각 프로젝트 시작 시 프로젝트별 서브 디렉토리 생성 규칙 정립 필요
  - execute 단계에서 SBOM 자동화 추가 검토
