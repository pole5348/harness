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

## 2026-04-25 — ECC 통합 v4 1단계 실행 완료 (`/se:execute`)

- **페르소나**: 보안 엔지니어 / 실행 단계
- **단계**: 1단계 — 환경 정리 + 단일 python3 + GPG 미도입 결정
- **진행 사항**:
  - `~/.claude/settings.json` 훅 명령: `python3` → `/usr/bin/python3` 절대경로 갱신
  - `hooks/model_switch.py` 신규 커맨드 매핑 추가:
    - `/se:learn sonnet` → claude-sonnet-4-6
    - `/se:learn opus` → claude-opus-4-7
    - `/se:learn rollback|audit|cleanup` → claude-sonnet-4-6
    - `/se:backup`, `/se:summary`, `/se:note` → claude-sonnet-4-6
    - `/se:learn` 인자 누락 시 `decision: block` + 사용법 안내 메시지 반환
  - `.env.example` 생성 (AWS, API Key, DB, OAuth 슬롯)
  - `.gitignore` 생성 (`.env`, 프로젝트별 `.env`, quarantine, 분기 history, DS_Store 등)
  - `_harness/permissions.md` 갱신 — GPG 미도입 결정, python3 경로 고정, 코딩 규칙(직접 쓰기 금지) 명시
  - `plan.md` 1단계 로드맵 `[x]` 완료 표시
  - obsidian 브랜치 삭제: 사용자 직접 처리 예정
- **이슈**: 없음
- **산출물**: `settings.json`, `hooks/model_switch.py`, `.env.example`, `.gitignore`, `_harness/permissions.md`
- **다음 단계**: 2단계 — 훅 보안 신뢰 루트 (manifest_root + self-check + 자동 갱신)

---

## 2026-04-25 — ECC 통합 v4 계획 확정 (`/se:confirm`)

- **계획 파일**: `_harness/security_engineer/plan.md` 저장 완료
- **3차 비판 모든 항목 사용자 수용**:
  - /se:note 시스템 도입 (4 타입: decision/rationale/tradeoff/concern)
  - .env 프로젝트별 (`_harness/projects/{프로젝트명}/.env`)
  - L4 의미 토큰 + 5초 카운트다운 (둘 다)
  - GPG 시작 미도입 (chmod 600), 운영 후 재검토
  - quarantine 30일 만료 정책 유지
  - /se:summary 수동 트리거 전용 명시
  - 30일 만료를 별도 /se:learn cleanup 커맨드로 분리 (SessionStart 분리)
- **추가 신규 결정**:
  - decisions_index.md 도입 (CLAUDE.md 직접 누적 금지)
  - 4주 자가 점검 일정 cautions.md 자동 기록
  - 시크릿 마스킹 강제 메커니즘 (pre-commit + 후처리 검증)
  - .env 동적 마스킹 패턴 등록 (메모리 내)
- **plan.md 감수해야 할 리스크 11개 명시**:
  1. 자연어 인젝션 검사 미도입
  2. 위협 모델 미작성
  3. rules/ 변조 감지 미도입
  4. 토큰 ROI 정량 평가 미수행
  5. 위험 Bash 차단 카테고리 부재
  6. GPG signed commit 미도입 (시작 시점)
  7. L1~L3 매번 다른 표현 미구현
  8. Continuous Learning ROI 무시
  9. 단위 테스트 작성 주체 미결정
  10. status.md git history 노이즈 감수
  11. user_decisions 카테고리 외부 입력 영향 잔여 위험
- **다음 단계**: `/se:execute`로 1단계(환경 정리 + obsidian 브랜치 삭제)부터 진행

---

## 2026-04-25 — ECC 통합 v3 3차 비판 라운드

- **비판 대상**: ECC 통합 v3 + 사용자 신규 결정사항
- **사용자 신규 요청**:
  - 사용자 고민·결론도 자동학습 대상에 포함 (방식 A 권장: /se:note 명시 마킹)
  - .env는 프로젝트별 관리, git 제외 강제
  - whitelist 형식: yaml
  - plan.md 표준 헤더는 /se:confirm 이후 적용
  - /se:summary 짧은 세션 거부 정책 불필요
  - 30일 만료 정책 추가 설명 요청 (답변 제공)
  - ROI 무시
  - GPG 설명 요청 (답변 제공)
- **수용 불가 항목**:
  - /se:note 시스템 미통합 상태로 9단계 진행 금지
  - .env "프로젝트" 정의·디렉토리 구조 미명시 상태로 3단계 진행 금지
  - L4 재타이핑 자동화 우회 대응 없이 6단계 진행 금지
  - 시크릿 마스킹 강제 메커니즘(pre-commit 후처리) 없이 3단계 진행 금지
  - 마스킹 함수 .env 동적 패턴 등록 경로 미정의 진행 금지
- **주요 PM/PO 비판**:
  - 사용자 결론 자동학습이 v3 9단계에 미통합
  - ".env 프로젝트별"의 프로젝트 정의 부재
  - plan.md 표준 헤더 적용 시점이 v3 plan 자체에 미적용 (status.md 4단계 동작 불능)
  - quarantine 만료 매체 미결정
  - /se:summary 자동 호출 위험 (정책 미명시)
- **주요 보안 비판**:
  - /se:note 마킹된 결론도 외부 입력 영향받을 수 있음 (출처 추적 필요)
  - L4 재타이핑 토큰의 클립보드 매크로 우회
  - 시크릿 마스킹 단일 진입점 강제 메커니즘 부재
  - status.md 이슈 제목에도 정보 누출 가능
  - .env 프로젝트별이면 마스킹 함수 동적 패턴 등록 경로 모호
  - self-check chicken-and-egg
  - manifest_root.sha256 갱신 자동화 부재
- **주요 재무 비판**:
  - /se:note로 인한 decisions/ 디렉토리 운영 부담
  - 마킹된 결론의 CLAUDE.md 비대화 (decisions_index.md로 분리 권장)
  - SessionStart 훅 책임 과대 (만료 정리 분리 필요)
  - /se:summary 자동 호출 시 짧은 세션 비용
- **신규 제안**:
  - /se:note <type> 시스템 (decision/rationale/tradeoff/concern)
  - decisions_index.md (CLAUDE.md 직접 누적 금지)
  - L4 토큰 의미 기반 생성
  - 30일 만료를 별도 /se:learn cleanup 커맨드로 분리
  - 4주 후 자가 점검 일정 자동 기록
  - GPG 도입은 운영 후 결정 (시작은 chmod 600)

---

## 2026-04-25 — ECC 통합 v3 계획 (2차 비판 + 사용자 답변 반영)

- **계획 대상**: ECC 통합 v3 — 2차 비판 모든 수용 불가 항목 반영
- **사용자 결정 반영**:
  - 자연어 인젝션 검사 → 7·8단계에서 완전 제거 (PM-1)
  - python3 → /usr/bin/python3 단일 사용 (PM-4)
  - 병행 진행 → 순차 진행으로 변경 (PM-6)
  - L4 매번 경고 + 재타이핑 패턴 (SEC-4, SEC-5)
  - status.md에 시크릿 미포함 (SEC-3)
  - history.md 시크릿 제외 + .env 별도 관리 + .gitignore 등록 (SEC-7)
  - 모든 history/status 쓰기 단일 마스킹 함수 (SEC-8, FIN-1)
  - /se:learn 매번 모델 인자 명시 (FIN-2)
  - status.md 자주 commit 노이즈 허용 (FIN-5)
- **신규 제안 (PM-3 / SEC-6 답변)**:
  - Continuous Learning 화이트리스트 yaml 도입
  - 자동 반영 가능: 도구 호출 순서 패턴, alias 제안, 빈도 메트릭, 거부 패턴 통계
  - 절대 자동 반영 금지: CLAUDE.md, rules/, agents/, skills/, hooks/, commands/
  - 임계값: 신뢰도 ≥ 0.9, 빈도 ≥ 3, 외부 출처 아님
  - 롤백 메커니즘: /se:learn rollback <commit-hash>, /se:learn audit
- **신규 정책**:
  - manifest_root.sha256 신뢰 루트 (chmod 600) + signed commit 권장
  - 모든 훅 self-check 첫 줄 + SessionStart 우선 등록
  - 30일 만료 정책 (quarantine → archive → 6개월 후 삭제)
  - L4 좁게 정의 + 무작위 4자 토큰 재타이핑
- **순차 진행 단계 (10단계)**:
  1. 환경 정리 + 단일 python3
  2. 훅 보안 신뢰 루트
  3. 시크릿 마스킹 단일 진입점 + history 분리
  4. /se:backup + status.md (메타데이터만)
  5. Stop 훅 + /se:summary
  6. PreToolUse Bash 위험도 (L4 재타이핑)
  7. rules/common/security.md (점진적)
  8. 단일 reviewer (자연어 인젝션 제거)
  9. Continuous Learning (화이트리스트 + 만료)
  10. 통합 검증 + 문서화
- **잔여 미결 질문**:
  - GPG signed commit 가능 여부
  - .env 사용 항목 범위
  - whitelist 형식 (yaml vs json)
  - 30일 만료 실행 매체
  - 4주 ROI 평가 방법

---

## 2026-04-25 — ECC 통합 2차 비판 라운드 (ecc-integration 브랜치)

- **계획 대상**: ECC 통합 v2 (1차 비판 + 사용자 답변 반영본)
- **수용 불가 항목**:
  - /se:learn 인자 모델 선택을 model_switch.py가 인식 못하는 상태 진행 금지
  - 7단계 자연어 인젝션 휴리스틱 검사 — 사용자 보류 결정 반영하여 제거 필수
  - Continuous Learning 부분 허용 화이트리스트 미정 상태로 8단계 진행 금지
  - manifest.sha256 신뢰 루트 미정 상태로 무결성 메커니즘 구축 금지
  - status.md 시크릿/컨텍스트 마스킹 정책 없이 git 동기화 금지
  - 모든 history/status 쓰기 경로 마스킹 단일 진입점 강제 필수
- **주요 보안 비판**:
  - manifest.sha256 자체의 무결성 보호 부재 (root of trust 없음)
  - SessionStart 훅이 다른 훅보다 먼저 실행 보장 없음 (race condition)
  - status.md가 git 동기화 매체로 격상되며 시크릿/컨텍스트 정책 부재
  - L4 매번 경고가 차단 대체 못함 — 사용자 피로 → 무심코 승인 위험
  - /se:learn이 quarantine 파일 read 시 인젝션 표면
  - 시크릿 마스킹이 모든 쓰기 경로에 적용된다는 보장 없음
  - shell rules가 bash + zsh 한 카테고리 처리는 차이 무시
- **주요 PM/PO 비판**:
  - 7단계의 자연어 인젝션 휴리스틱이 보류 결정 미반영
  - /se:learn 모델 인자가 모델 자동 전환 훅과 충돌
  - "Continuous Learning 부분 허용 검토"가 8단계와 충돌, 정의 부재
  - python3 두 경로 분기 로직 미명시
  - /se:backup의 plan.md 로드맵 추출 형식 미정의
  - 병행 진행 시 단계 간 자원 충돌 미파악 (manifest, history, rules 디렉토리)
- **주요 재무 비판**:
  - rules/ 7개 일괄 자동 작성 비용 + 향후 확장 비용
  - manifest.sha256 매번 수동 갱신 운영 부담
  - quarantine 무한 적체 디스크/정리 비용
  - status.md 자주 commit하면 git history 노이즈
- **재계획 시 필수 포함**:
  1. python3 wrapper script 또는 머신별 settings 분리
  2. /se:learn 인자 처리 명세 + 디폴트 정책
  3. 7단계 자연어 인젝션 휴리스틱 제거
  4. Continuous Learning 자동 반영 화이트리스트
  5. manifest.sha256 신뢰 루트 정의
  6. status.md 메타데이터만 정책 + 마스킹 범위
  7. 모든 history/status 쓰기 단일 함수 강제
  8. 단계 의존 그래프 + 병행 그룹 정의
  9. shell rules bash/zsh/posix 분리
  10. L4 등급 객관 기준 + 사용자 검토용 분류표
  11. manifest 자동 갱신 메커니즘
  12. quarantine 만료 정책

---

## 2026-04-25 — ECC 통합 1차 비판 라운드 (ecc-integration 브랜치)

- **계획 대상**: everything-claude-code 기능 하네스 통합 계획 (사용자 답변 반영본)
- **수용 불가 항목**:
  - Continuous Learning 자동 반영 절대 비활성 — 제안→수동승인→diff검토→commit 워크플로 강제
  - 위험 Bash "모두 경고" 부분 수정 — 명백한 파괴 패턴(rm -rf /, dd, mkfs, 포크폭탄, 광범위 chmod 0)은 차단
  - status.md 사양 명시 없이 시작 금지
  - 훅 무결성·권한 강화 누락 금지
  - 외부 입력 기반 학습 비활성화
- **주요 보안 비판**:
  - 자동학습이 시스템 프롬프트 오염 경로 (외부 PoC/취약점 문서가 학습되면 영구 오염)
  - 훅 스크립트 자체가 RCE 표적 (chmod 600, 무결성 검증 필요)
  - settings.json의 python3 PATH 의존 — 절대경로 명시 필요
  - rules/ 파일 변조 시 보안 가이드 우회 가능
  - Stop 훅 자동 요약이 시크릿/PII 평문 기록 경로 (마스킹 또는 .gitignore)
  - 프롬프트 인젝션 검출 패턴 매칭만으로는 false negative 다발
- **주요 PM/PO 비판**:
  - status 파일 사양 전무 (경로/스키마/동시성)
  - "안정화 후" 등 의존 조건 모호
  - 일정 추정에 테스트·문서화 누락 (실제 12~15일 예상)
  - 브랜치 머지 전략 미수립
- **주요 재무 비판**:
  - rules/ 자동 로드 시 토큰 폭증 (60% 절감 목표와 역행)
  - Stop 훅 "전체 세션 요약"에 LLM 호출 필요 — 매 세션 비용
  - 4언어 reviewer 분리의 유지보수·토큰 N배 비용
  - Continuous Learning 검토에 사용자 주당 1~2시간 추가 비용
  - 토큰 최적화 60%의 베이스라인 측정 부재
- **재계획 시 필수 포함 사항**:
  1. 위협 모델 1쪽
  2. status.md 사양 (경로/스키마/동시성)
  3. 위험 Bash 정책 매트릭스 (차단/경고/통과)
  4. Continuous Learning 워크플로 + cautions.md 위치
  5. 훅 보안 정책 (권한/무결성/python3 절대경로)
  6. rules/ 로딩 정책 (정적/동적, 단계별 매핑)
  7. 베이스라인 메트릭 측정 항목
  8. 브랜치 머지 전략
  9. 운영 단계 (7단계) 추가
  10. 일정 테스트·문서화 가산

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
