# Claudian 설정 디렉토리

이 디렉토리는 Claudian이 세션 메타데이터를 저장하는 곳입니다.

## 이 볼트에서의 Claudian 사용법

볼트 = 하네스 레포이므로, Claude Code 슬래시 커맨드가 그대로 작동합니다.

### 설치 확인 사항
- Obsidian → 설정 → 커뮤니티 플러그인 → Claudian 설치 및 활성화
- Claude Code CLI가 설치되어 있어야 함 (`which claude`)

### 커맨드
하네스 커맨드(`/se:plan`, `/teacher:ask` 등)는 Claudian 채팅창에서 그대로 사용합니다.

### @멘션으로 파일 참조
- `@_harness/security_engineer/plan.md` — 현재 프로젝트 계획 참조
- `@_harness/history.md` — 진행 이력 참조
- `@_harness/security_engineer/review_report.md` — 검토 리포트 참조

### 볼트 구조 활용
- `_harness/` — 에이전트 정의 및 프로젝트 산출물 (Obsidian에서 노트로 열람 가능)
- `_harness/student/docs/` — `/teacher:doc` 학습 노트 저장 위치
