# 프로젝트 계획: ECC 통합 v4 (최종 확정)

> 확정일: 2026-04-25  
> 브랜치: `ecc-integration`  
> 비판 라운드 3회 + 사용자 답변 모두 반영. 미해결·보류·감수 리스크는 본 문서 하단에 명시.

---

## 개요

- **목표**: `everything-claude-code`의 검증된 기능 중 하네스에 부재한 핵심 요소를, 신뢰 루트와 단일 마스킹 진입점을 갖춘 안전한 단계별 구조로 통합한다. `/se:note` 시스템으로 사용자 결론·고민도 학습 대상에 포함하되 외부 입력 영향은 차단한다.
- **범위**:
  - 환경 정리: `obsidian` 브랜치 삭제, `python3` 단일 경로(`/usr/bin/python3`), GPG 미도입(시작은 chmod 600)
  - 훅 보안: `manifest_root.sha256` 신뢰 루트 + 모든 훅 self-check + SessionStart 우선 + pre-commit 자동 갱신
  - 시크릿 처리: 단일 마스킹 함수(`safe_write.py`) + `.env` 프로젝트별 + 동적 패턴 등록 + pre-commit 후처리 검증
  - 신규 커맨드: `/se:backup`, `/se:summary`(수동), `/se:learn <model>`, `/se:learn rollback`, `/se:learn audit`, `/se:learn cleanup`, `/se:note <type>`
  - history 다중 세션 분리 + `/se:backup` 시 병합
  - status.md (메타데이터만 + 이슈 제목 마스킹)
  - Stop 훅 (메타데이터만, LLM 호출 없음)
  - PreToolUse Bash 위험도: L4는 명령에서 추출한 의미 토큰 + 5초 카운트다운
  - rules/common/security.md (점진적 1개 우선)
  - 단일 reviewer 서브에이전트 (자연어 인젝션 휴리스틱 제거)
  - Continuous Learning: 화이트리스트 yaml + `/se:note` 4타입 + decisions_index.md + 30일 만료
- **제외 범위 (이번 라운드 미도입)**:
  - 자연어 프롬프트 인젝션 검사 (PM-1: 향후 검토)
  - 위협 모델 정식 작성 (보류)
  - `rules/` 변조 감지 (보류)
  - 토큰 베이스라인 측정 / ROI 정량 평가 (보류)
  - 위험 Bash 차단 카테고리 (사용자 결정으로 모든 등급 경고+승인)
  - GPG signed commit (운영 안정화 후 재검토)
  - 위험 Bash "L1~L3" 매번 다른 표현으로 출력 (구현 부담 대비 효익 낮음, 보류)
- **성공 기준**:
  - `/se:backup` 실행 시 `_harness/status.md`에 단계·로드맵·이슈 메타데이터 기록 (시크릿·컨텍스트 비포함, 이슈 제목 마스킹)
  - 모든 history/status 쓰기가 `safe_write.py`를 통과 (pre-commit으로 강제)
  - `manifest_root.sha256` ↔ `manifest.sha256` ↔ 훅 파일 3단계 검증 동작
  - L4 명령은 명령에서 추출한 의미 토큰 입력 + 5초 카운트다운 후에만 진행
  - Continuous Learning 자동 반영은 화이트리스트 카테고리에만 적용, CLAUDE.md/rules/agents/skills/hooks/commands 영역은 절대 자동 반영 안 됨
  - `/se:note <type>` 마킹 시 외부 입력 출처 자동 첨부, 외부 출처면 quarantine 단계 추가
  - `.env`가 프로젝트별로 `_harness/projects/{프로젝트명}/.env`에 위치하고 `.gitignore`로 강제 제외
  - 안정화 디폴트: 훅 단위 테스트 통과 + 7일 운영 무사고

---

## 기술 스택

- `/usr/bin/python3` (고정)
- Bash (검증 스크립트)
- Claude Code 훅: `UserPromptSubmit`, `Stop`, `PreToolUse`, `SessionStart`
- Claude Code subagent (frontmatter `model`, `tools`)
- `hashlib` (표준 라이브러리)
- `fcntl.flock` (다중 세션 동시성)
- yaml (whitelist.yaml — Python `yaml` 라이브러리, 미설치 시 `pip install pyyaml` 안내)
- Git pre-commit hook
- macOS arm64/Intel 양쪽 호환

---

## 로드맵 진행률

| 단계 | 상태 | 완료일 |
|---|---|---|
| 1단계: 환경 정리 + 단일 python3 + GPG 미도입 결정 | [x] | 2026-04-25 |
| 2단계: 훅 보안 신뢰 루트 (manifest_root + self-check + 자동 갱신) | [ ] | - |
| 3단계: 시크릿 마스킹 단일 진입점 + history 분리 + .env 프로젝트별 | [ ] | - |
| 4단계: `/se:backup` + status.md 메타데이터 (이슈 제목 마스킹) | [ ] | - |
| 5단계: Stop 훅 메타데이터 + `/se:summary` 수동 전용 | [ ] | - |
| 6단계: PreToolUse Bash L4 의미토큰 + 카운트다운 | [ ] | - |
| 7단계: `rules/common/security.md` 점진적 작성 | [ ] | - |
| 8단계: 단일 reviewer 서브에이전트 (자연어 인젝션 제거) | [ ] | - |
| 9단계: Continuous Learning + `/se:note` + decisions_index + cleanup | [ ] | - |
| 10단계: 통합 검증 + 문서화 + main 머지 준비 | [ ] | - |

---

## 실행 단계 (순차 진행)

### 1단계: 환경 정리 + 단일 python3 + GPG 미도입 결정
- **태스크**:
  - `obsidian` 브랜치의 미반영 변경 확인 (`git diff main..obsidian`) → 사용자 확인 후 `git branch -D obsidian`
  - `~/.claude/settings.json`의 모든 훅 명령을 `/usr/bin/python3` 절대경로로 갱신
  - `model_switch.py`에 신규 커맨드 매핑 추가:
    - `/se:learn\s+(sonnet|opus)` → 인자 따라 모델 결정
    - `/se:learn\s+(rollback|audit|cleanup)` → sonnet
    - `/se:backup`, `/se:summary`, `/se:note` → sonnet
  - 인자 누락 시(`/se:learn`만 입력) 사용자에게 모델 명시 요청 메시지 출력
  - `_harness/permissions.md`에 "GPG 미도입 결정 — 시작은 chmod 600, 운영 후 재검토" 명시
  - `.env.example` 템플릿 생성 (AWS Access Key, API Key 슬롯)
  - `.gitignore`에 `.env`, `_harness/projects/*/.env`, `_harness/history*.md`, `_harness/continuous_learning/quarantine/` 등록
- **산출물**:
  - 갱신된 `~/.claude/settings.json`, `hooks/model_switch.py`
  - `.env.example`, 갱신된 `.gitignore`, 갱신된 `_harness/permissions.md`
  - obsidian 브랜치 삭제 완료

### 2단계: 훅 보안 신뢰 루트 + 자동 갱신
- **태스크**:
  - `hooks/manifest.sha256` 생성 — 각 훅 스크립트의 SHA256 목록
  - `~/.claude/manifest_root.sha256` 생성 — `hooks/manifest.sha256` 자체의 SHA256 (chmod 600)
  - `hooks/session_start.py` 작성:
    - root → manifest → 모든 훅 3단계 검증
    - 각 훅 self-check 코드도 부모(SessionStart)에서 검증 (chicken-and-egg 보강)
    - 불일치 시 `_harness/integrity_alert.md` 기록 + `_harness/.hooks_verified` 마커 생성 안 함
    - 다른 훅들은 `_harness/.hooks_verified` 마커 확인 후에만 동작 (선두 자물쇠)
  - 모든 훅 스크립트(`model_switch.py` 포함) 첫 줄에 self-check 추가
  - `~/.claude/settings.json`에 `SessionStart` 훅을 **첫 번째**로 등록
  - 모든 `hooks/*.py` 권한 `chmod 600`
  - `scripts/update_manifest.sh` 작성 — manifest.sha256 + manifest_root.sha256 동시 갱신
  - git pre-commit hook 설치 (`.git/hooks/pre-commit`):
    - hooks/ 변경 감지 → `update_manifest.sh` 자동 실행
    - 시크릿 마스킹 후처리 검증 (3단계와 연동)
- **산출물**:
  - `hooks/session_start.py`, `hooks/manifest.sha256`
  - `~/.claude/manifest_root.sha256` (권한 600)
  - `scripts/update_manifest.sh`, `.git/hooks/pre-commit`
  - 모든 훅에 self-check 추가
  - 갱신된 `_harness/permissions.md`

### 3단계: 시크릿 마스킹 단일 진입점 + .env 프로젝트별 + history 분리
- **태스크**:
  - 디렉토리 구조 정의: `_harness/projects/{프로젝트명}/.env` (하네스 진행 각 작업이 프로젝트)
  - `_harness/projects/.gitkeep` 생성, 실제 프로젝트 .env는 .gitignore로 강제 제외 (1단계 완료)
  - `hooks/lib/safe_write.py` 작성:
    - `write_with_masking(path, content)` — 모든 history/status 쓰기 단일 진입점
    - 정적 마스킹: API 키 패턴(`sk-`, `ghp_`, `AIza`, `xoxb-`, AWS access key, JWT, SSH key 시작), 이메일, IP, `password=`, `secret=`, `token=`
    - 동적 마스킹: 시작 시 `~/.env`, `_harness/projects/*/.env` 자동 스캔 → 값을 메모리 내 패턴 등록 (디스크 저장 안 함)
    - 민감 키워드(고객명·프로덕션·PoC·exploit·우회 등)는 `[REDACTED:title]` 처리
    - 직접 `open()+write()` 사용 금지 → `_harness/permissions.md` 코딩 규칙 명시
  - 다중 세션 감지: history.md `flock` 시도, 실패 시 `_harness/history_{YYYYMMDD_HHMMSS}.md` 분기
  - pre-commit hook에 직접 쓰기 패턴 검출 추가 (hooks/, commands/ 내 history|status 직접 open+write 차단)
  - `hooks/lib/secret_patterns.json` (정적 패턴 목록 분리)
- **산출물**:
  - `hooks/lib/safe_write.py`, `hooks/lib/secret_patterns.json`
  - `_harness/projects/.gitkeep`
  - 갱신된 pre-commit hook
  - 갱신된 `_harness/permissions.md` (코딩 규칙 + 프로젝트 디렉토리 정의)

### 4단계: `/se:backup` + status.md (메타데이터만, 이슈 제목 마스킹)
- **태스크**:
  - **이번 v4 plan에 표준 로드맵 헤더가 이미 포함되어 있음** — 별도 변환 불필요
  - 향후 plan.md는 `/se:confirm` 시 표준 헤더 자동 생성 (`commands/se/confirm.md` 갱신)
  - `_harness/status.md` 스키마 정의:
    ```markdown
    # Project Status
    - 마지막 갱신: <timestamp>
    - 현재 페르소나: 보안 엔지니어
    - 현재 단계: 실행 (3/10)
    - 로드맵 위치: 3단계 시크릿 마스킹 (in progress)
    - 진행 중 이슈: 2건 (ID: ISSUE-001, ISSUE-003)
    - 해결 이슈 (이번 주): 1건 (ID: ISSUE-002, 해결일 YYYY-MM-DD)
    - 다음 예정 단계: 4단계 /se:backup 커맨드
    ```
  - `commands/se/backup.md` 작성:
    - plan.md `## 로드맵 진행률` 표 정규 파싱
    - 분기된 history 파일들(`history*.md`) 통합 읽기
    - 이슈 추출: ID/제목만 (제목은 `safe_write.py`로 마스킹)
    - status.md를 `safe_write.py`로 작성
- **산출물**:
  - `commands/se/backup.md`
  - 갱신된 `commands/se/confirm.md` (표준 헤더 자동 생성 로직)
  - `_harness/status.md` (초기 템플릿)

### 5단계: Stop 훅 (메타데이터만) + `/se:summary` (수동 전용)
- **태스크**:
  - `hooks/session_stop.py` 작성 — **LLM 호출 없음**:
    - 세션 ID, 시작/종료 시각, 사용 슬래시 커맨드 목록, 변경 파일 목록(`git status` 또는 도구 호출 로그), 최종 페르소나·단계
    - `safe_write.py`로 history.md(또는 분기 파일) append
  - `~/.claude/settings.json`에 `Stop` 훅 등록
  - `commands/se/summary.md` 작성:
    - 첫 줄에 "**수동 트리거 전용 — `Stop` 훅이나 자동화에서 호출 금지**" 명시
    - 트랜스크립트 요약 + 핵심 결정 + 다음 단계 제안
    - 모델: sonnet (model_switch.py 매핑)
- **산출물**:
  - `hooks/session_stop.py`
  - `commands/se/summary.md`
  - 갱신된 `settings.json`, `manifest.sha256`(자동)

### 6단계: PreToolUse Bash 위험도 (L4 의미 토큰 + 카운트다운)
- **태스크**:
  - L1~L4 객관 기준을 `_harness/permissions.md`에 정의:
    | 등급 | 복구 가능성 | 영향 범위 | 되돌림 비용 |
    |---|---|---|---|
    | L4 | 불가 | 시스템·디스크·디바이스 | ∞ |
    | L3 | 어려움 | 레포 전체·원격 | 높음 |
    | L2 | 가능 | 디렉토리·프로세스 | 중간 |
    | L1 | 쉬움 | 단일 파일·세션 | 낮음 |
  - `hooks/bash_safety.py` 작성:
    - L4 패턴(좁게): `rm -rf /`, `rm -rf /*`, `dd of=/dev/sd[a-z]`, `mkfs\..*`, `:(){:|:&};:`, `chmod -R 0 /`
    - L4 발견 시 **명령에서 의미 토큰 추출** (예: `rm -rf /Users/foo` → `EXEC-DESTROY-USERS-FOO`) 사용자에게 표시
    - 추가로 `additionalContext`에 "이 명령을 실행하려면 5초 후 위 토큰을 다시 입력하세요" 메시지
    - L1~L3는 등급 + 영향 범위 + 복구 가능성 정보만 출력 (사용자 매번 다른 표현 출력은 보류)
  - `hooks/lib/bash_patterns.json` 패턴 목록 분리
  - `~/.claude/settings.json`에 `PreToolUse` matcher `Bash` 등록
- **산출물**:
  - `hooks/bash_safety.py`, `hooks/lib/bash_patterns.json`
  - 갱신된 `_harness/permissions.md`
  - 갱신된 `settings.json`, `manifest.sha256`

### 7단계: 보안 코딩 규칙 (점진적 — security.md만 우선)
- **태스크**:
  - `rules/common/security.md` Claude 자동 작성 (OWASP Top 10 기반)
  - 파일 상단에 "Claude 자동 작성, 향후 사용자/보안팀 새로 작성 가능" 명시
  - `commands/se/execute.md` 갱신: 실행 시 `rules/common/security.md` 명시적 read
  - `commands/se/review.md` 갱신: review 시 동일하게 read
- **산출물**:
  - `rules/common/security.md`
  - 갱신된 `commands/se/execute.md`, `commands/se/review.md`

### 8단계: 단일 reviewer 서브에이전트 (자연어 인젝션 제거)
- **태스크**:
  - `agents/code-security-reviewer.md` 정의 (Sonnet, frontmatter `model`):
    - 입력: 검토 대상 파일 경로 또는 코드 블록
    - 동작: 확장자/명시 언어 분기 → `rules/common/security.md` 로드 → 보안 검토
    - **자연어 인젝션 휴리스틱 검사 항목 완전 제거** (사용자 결정)
    - 단일 reviewer 운영 — 코드량 증가 시 언어별 분리 검토
  - `~/.claude/agents/code-security-reviewer.md`로 심볼릭 링크
  - `commands/se/review.md`에 이 agent 호출 로직 추가
  - `_harness/security_engineer/04_review.md`에서 자연어 인젝션 항목 제거
- **산출물**:
  - `agents/code-security-reviewer.md`
  - 갱신된 `commands/se/review.md`, `_harness/security_engineer/04_review.md`

### 9단계: Continuous Learning + `/se:note` + decisions_index + cleanup
- **태스크**:
  - `_harness/continuous_learning/whitelist.yaml` 작성:
    ```yaml
    auto_apply:
      tool_sequence_patterns: true
      alias_suggestions: true
      frequency_metrics: true
      rejected_pattern_stats: true
      user_decisions: true   # /se:note 마킹 (외부 출처 아닌 경우만)
    manual_only:
      claude_md: true
      rules: true
      agents: true
      skills: true
      hooks: true
      commands: true
    thresholds:
      min_confidence: 0.9
      min_occurrence: 3
      exclude_external_origin: true
    ```
  - `skills/continuous_learning/extractor.md` — 외부 입력 출처 차단 로직 + quarantine 저장
  - `_harness/continuous_learning/cautions.md`:
    - 마커 `<!-- AUTO_PREPEND_HERE -->` 위에 자동 반영 주간 요약 추가
    - 9단계 종료 4주 후 자가 점검 일정 자동 기록
  - `_harness/continuous_learning/WARNINGS.md` — 위험 시나리오·검토 권장
  - `_harness/continuous_learning/decisions_index.md` — `/se:note` 마킹 결론 시간순 정리 (CLAUDE.md 직접 누적 금지)
  - `commands/se/note.md` 작성:
    - 형식: `/se:note <type> <내용>` (type: decision/rationale/tradeoff/concern)
    - 직전 N분(기본 10분) 외부 입력 출처 자동 첨부
    - 외부 출처 있으면 quarantine으로 우회, 없으면 decisions_index.md 즉시 추가
  - `commands/se/learn.md` (인자 필수): `/se:learn <sonnet|opus>` — quarantine 검토·수락·거부, dry-run 모드 우선
  - `commands/se/learn-rollback.md`: `/se:learn rollback <commit-hash>`
  - `commands/se/learn-audit.md`: `/se:learn audit` — 일주일치 자동 반영 점검
  - `commands/se/learn-cleanup.md`: `/se:learn cleanup` — 30일 만료 quarantine을 `archive/{YYYYMM}/`로 이동, 6개월 후 삭제 (수동 트리거)
- **산출물**:
  - `_harness/continuous_learning/` 디렉토리 (whitelist.yaml, cautions.md, WARNINGS.md, decisions_index.md, quarantine/)
  - `skills/continuous_learning/extractor.md`
  - `commands/se/note.md`, `learn.md`, `learn-rollback.md`, `learn-audit.md`, `learn-cleanup.md`
  - 갱신된 `model_switch.py`, `manifest.sha256`

### 10단계: 통합 검증 + 문서화 + main 머지 준비
- **태스크**:
  - 각 훅·커맨드 수동 시뮬레이션 입력 검증
  - 안정화 기준: 훅 단위 테스트 통과 + 7일 운영 무사고 (사용자 디폴트, 향후 변경 가능)
  - 단위 테스트 작성 주체 사용자와 재논의 (PM-7 보류 결정)
  - README.md, CLAUDE.md 종합 갱신:
    - 신규 커맨드 등재 (`/se:backup`, `/se:summary`, `/se:learn <model>`, `/se:learn rollback/audit/cleanup`, `/se:note <type>`)
    - whitelist.yaml 사용법
    - L1~L4 분류표
    - 시크릿 마스킹 정책 + .env 프로젝트별 정책
    - manifest 신뢰 루트 정책 + GPG 미도입 결정
    - 이 plan.md의 "감수해야 할 리스크" 요약 링크
  - main 머지 준비 (사용자 수동 머지)
- **산출물**:
  - 갱신된 README.md, CLAUDE.md
  - `_harness/history.md` 종합 기록 + 안정화 측정 결과

---

## 식별된 리스크 (사전 — 완화 조치 동반)

| 리스크 | 가능성 | 영향도 | 완화 조치 |
|---|---|---|---|
| L4 의미 토큰 + 카운트다운 우회 (자동완성·매크로) | 낮음 | 높음 | 토큰이 명령 의존 → 매번 다름. 카운트다운으로 시간 강제 |
| manifest_root.sha256 chmod 600 단독 보호 한계 | 중 | 높음 | 운영 안정화 후 GPG 전환 검토 |
| `/se:note` 마킹 결론이 외부 영향 받은 경우 자동 반영 | 중 | 높음 | 직전 10분 외부 입력 출처 자동 첨부 → 외부 있으면 quarantine 우회 |
| 시크릿 마스킹 강제 메커니즘(pre-commit) 우회 | 낮음 | 높음 | pre-commit + 후처리 검증 이중. truffleHog 류 도구 추가 검토 |
| Continuous Learning whitelist 카테고리 잘못 분류 | 중 | 높음 | 변경 시 git commit + diff 검토 강제. 4주 자가 점검 시 분류 재평가 |
| 다중 세션 history 분기 후 병합 충돌 | 낮음 | 낮음 | `/se:backup` 시점 처리, 충돌 시 사용자 표시 |
| pre-commit hook 다른 협업자 환경 미설치 | 중 | 중 | README에 설치 가이드 명시. CI에서도 동일 검증 (향후) |
| 30일 만료 수동 트리거(`/se:learn cleanup`) 누락 | 중 | 중 | cautions.md 상단에 만료 후보 카운트 표시 → 사용자 가시성 확보 |
| obsidian 브랜치 미반영 변경 손실 | 낮음 | 중 | 1단계 git diff 확인 필수 |
| GPG 미도입으로 manifest 위조 위험 | 낮음 | 높음 | 운영 안정화 후 도입 결정 — 그 전까지 chmod 600 + signed commit 권장(선택) |

---

## 감수해야 할 리스크 (사용자 명시 수용 — 별도 완화 조치 없음 또는 부분만)

> 사용자가 본 라운드에서 의식적으로 도입 보류·수용을 선택한 항목들. 향후 운영 중 발견되면 재계획 대상.

1. **자연어 프롬프트 인젝션 검사 미도입** (PM-1 결정)
   - 영향: `Skills.md`, 마크다운 코멘트, 외부 자연어 문서에 포함된 인젝션 패턴이 검출되지 않음. 보안 엔지니어 워크플로(외부 PoC/문서 분석)에서 false negative 발생 시 시스템 프롬프트가 영향받을 수 있음.
   - 사용자 결정 근거: 향후 검토.

2. **위협 모델 정식 작성 미수행** (보안-9 보류)
   - 영향: 자산·행위자·시나리오의 명시적 정의가 없어 잔여 리스크 우선순위 판단 어려움. 새 위협 발견 시 대응 지연 가능.
   - 사용자 결정 근거: 보류.

3. **`rules/` 변조 감지 미도입** (보안-6 보류)
   - 영향: `rules/common/security.md` 등이 변조될 경우 보안 가이드라인 자체가 거꾸로 동작하여 `/se:execute`가 보안 규칙을 어기면서 정상으로 판단할 수 있음.
   - 완화 (부분): pre-commit + git diff 알림으로 변경 감지 가능 (자동 차단 아님).

4. **토큰 베이스라인 측정 / ROI 정량 평가 미수행** (재무-5,6 보류, ROI 무시)
   - 영향: 통합 후 비용·속도 효과를 객관적으로 검증 불가. Continuous Learning 무용성을 늦게 발견할 가능성.
   - 완화 (부분): 9단계 4주 후 자가 점검 1회 캘린더 자동 기록 (정성 평가).

5. **위험 Bash 차단 카테고리 부재** (사용자 결정)
   - 영향: L4 명령도 사용자가 토큰 입력하면 진행됨. 시스템 손실 사고 가능성 존재.
   - 완화 (부분): 의미 토큰 + 5초 카운트다운으로 인지 비용 최대화. 그러나 본질적으로 사용자가 결정 시 막을 수 없음.

6. **GPG signed commit 미도입 (시작 시점)**
   - 영향: `manifest_root.sha256` 보호가 chmod 600에만 의존. 사용자 권한 RCE 시 모두 무력화.
   - 완화: 운영 안정화 후 GPG 전환 검토 (재무 부담과 보호 강화의 균형).

7. **위험 Bash L1~L3 매번 다른 표현 출력 미구현** (구현 부담 대비 효익 낮아 보류)
   - 영향: 사용자가 같은 메시지 반복 시 무시 패턴 형성.
   - 완화 (부분): L4만 의미 토큰 + 카운트다운으로 차별화.

8. **Continuous Learning ROI 정량 평가 무시** (사용자 결정)
   - 영향: 4주 후 도입 가치 판단 시 정량 근거 없음.
   - 완화 (부분): 4주 자가 점검 1회 정성 평가.

9. **단위 테스트 작성 주체 미결정** (PM-7 보류)
   - 영향: 10단계 진입 시 안정화 기준(훅 단위 테스트 통과) 충족 판단 지연 가능.
   - 완화: 9단계 종료 시점에 사용자와 재논의.

10. **status.md `git push` 시 git history 노이즈** (FIN-5 사용자 수용)
    - 영향: 잦은 status 갱신으로 commit log 도배. 다른 PR 리뷰 시 노이즈.
    - 사용자 결정: 그때그때 업데이트 — 노이즈 감수.

11. **Continuous Learning 부분 허용 — `user_decisions` 카테고리의 자동 반영 위험**
    - 영향: 사용자가 내린 결론이라도 외부 입력에 영향받았을 수 있음. 외부 출처 자동 첨부 메커니즘이 누락 검출 시 잘못된 결론이 자동 반영됨.
    - 완화: 직전 10분 외부 입력 자동 첨부. 그러나 10분 이전 영향은 추적 못 함.

---

## 미결 질문 / 확인 필요 사항

> 본 plan으로 실행 진입은 가능하나 운영 중 또는 단계 진입 시 결정 필요한 사항.

1. **`/usr/bin/python3` 버전 호환성** (1단계 시작 시): 시스템 파이썬 버전이 3.x 미만이면 별도 설정 필요. 1단계 첫 작업으로 `/usr/bin/python3 --version` 확인.
2. **`.env` 사용 항목 확장** (3단계): AWS Access Key, API Key 외 추가 항목 (DB 비밀번호, OAuth secret 등) 명시 필요 시 권장.
3. **단위 테스트 작성 주체** (10단계 진입 시): Claude 자동 작성 vs 사용자 직접 작성 vs 단위 테스트 생략 후 통합 시나리오만.
4. **GPG 도입 시점** (10단계 이후 운영 중): 안정화 7일 후 도입 결정 시점 명시.
5. **`/se:note` 외부 입력 추적 윈도우** (9단계 시작 시): 직전 10분 디폴트 — 변경 시점 결정.
6. **언어별 rules 추가 시점** (운영 중): Python/TypeScript/Go/Shell 중 어느 것이 먼저 필요해질지 운영 중 판단.

---

## 참고 산출물 인덱스

| 항목 | 위치 |
|---|---|
| 비판 라운드 이력 | `_harness/history.md` |
| 권한·정책 | `_harness/permissions.md` |
| 실행 단계 라이브러리 | `_harness/security_engineer/execute_library.md` |
| 검토 리포트 (운영 후) | `_harness/security_engineer/review_report.md` |
| 프로젝트별 .env | `_harness/projects/{프로젝트명}/.env` |
| 시크릿 마스킹 함수 | `hooks/lib/safe_write.py` |
| 매니페스트 신뢰 루트 | `~/.claude/manifest_root.sha256` |
