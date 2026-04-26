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

## 2026-04-26 — wiki4lazy 1차 비판 라운드 (`/se:critique`)

- **비판 대상**: wiki4lazy 1차 계획 + 미결 답변 반영안 (작업공간 `/Users/pole/scripts/projects/wiki4lazy`)
- **사용자 미결 답변 요약**:
  1. MVP=Obsidian → Confluence/Notion 후속
  2. Bedrock=Sonnet 3.5 또는 inference profile로 Opus/Claude 4.5 의향
  3. 컨펌=Slack DM
  4. 발행 권한 통제 없음 (모두 허용)
  5. 데이터 분류 정책 없음, 일반 지식만
  6. 리전=ap-northeast-2 한정
  7. 비용 한도=월 1만원 미만 (인프라+Bedrock 전체)
  8. 로그 보존=1일
  9. IaC=Terraform
  10. Obsidian 로컬 직접 sync
- **총평**: 답변 2(Opus) + 답변 6(서울 한정) + 답변 7(1만원) 3중 충돌. 답변 4(권한 없음) + 답변 7(예산) = rate limit 강제 미하면 비용 폭주.
- **수용 불가 항목**:
  1. Opus + ap-northeast-2 + 1만원 동시 운영 — Sonnet 3.5 고정으로 수정
  2. Rate limit 부재 — 권한 통제와 별개로 강제
  3. Obsidian sync 메커니즘 미결정 — 1단계 산출물에 ADR 의무
  4. CloudWatch Logs 1일 → 7일 상향
  5. 컨펌 콜백 HMAC + JTI + TTL 강제
- **PM/PO 비판**:
  1. MVP를 가장 어려운 채널(Obsidian 로컬 sync)부터 시작
  2. 성공 기준 60초 회신이 P50/P95 분리 안 됨
  3. 단계 10개가 1만원 예산·1인 가정에 비현실적
  4. README 1차안과 결정 사이 의미 불일치 (Obsidian이 1차 가공인지 발행 채널인지)
- **보안 비판**:
  5. Obsidian sync 4개 옵션(SSH/S3/Git/Cloud) 보안 영향 미평가
  6. 권한 없음 + rate limit 없음 = DoS+비용 폭주 결합
  7. 데이터 분류 정책 없음 + 입력 가드 없음 — 시크릿 정규식 1차 차단 권장
  8. CloudWatch 1일 = 보안 사고 사후 분석 불가
  9. Slack DM 컨펌 = im:write 권한 추가 + 콜백 위변조 표면
  10. inference profile cross-region = 거주성 위반
  11. Slack 토큰 회전 정책 부재
  12. 인젝션 → Obsidian 마크다운 → 로컬 PC 트래킹/RCE 표면
- **재무 비판**:
  13. Opus 1회 약 235원 → 약 42회/월에 한도 도달
  14. Secrets Manager 시크릿 5개 = 2,800원 차지 — 1개 JSON 묶음 또는 SSM SecureString 권장
  15. NAT Gateway = 예산 4~6배 초과 → Lambda는 VPC 외부 강제 (보안 약화 수용)
  16. 알람만으로는 차단 안 됨 — AWS Budgets Action 자동 IAM 박탈 권장
  17. 로그 1일 단축의 절감 효과 미미 (인입량이 비용 결정 요인)
- **재계획 시 필수 포함**:
  1. 월 1만원 예산표 (서비스별 단가 + 호출량 가정 + 합계 검증)
  2. Bedrock 모델=Sonnet 3.5 기본 + Opus 토글·일일 N회 한도
  3. 사용자별 Rate limit 구체 수치
  4. Obsidian sync 채널 ADR
  5. cross-region inference profile 사용 금지 명시
  6. 컨펌 HMAC + JTI + TTL 메커니즘
  7. CloudWatch 7일 + (선택) S3 archive 30일
  8. Markdown 화이트리스트 필터 정책
  9. AWS Budgets Action 자동 차단 정의
  10. 단계 6개로 압축
  11. README 1차안 충돌 해소
- **다음 단계**: 사용자 결정 후 `/se:plan` 재계획 또는 일부 항목 수용 거절 표명

---

## 2026-04-26 — ECC 통합 v5 확정 (`/se:confirm` + 구조 개편)

- **계기**: v4 토큰 비용 비판 결과를 사용자가 항목별 결정 → v5 재확정
- **사용자 결정 수용 매핑**:
  - PM-1: plan.md 슬라이싱 (헤더+로드맵+링크 / 단계 본문 `plan/{N}.md`) ✅
  - PM-2: 의무 로드 파일 1~2개 압축, permissions/execute_library 조건부 로드 ✅
  - PM-3: `/se:critique --diff` 옵션 도입 (격리 원칙 일부 완화) ✅
  - PM-4: `/se:backup` 변경 없으면 skip + 수동 운영 전제 ✅
  - PM-5: 사용자 미해석 — 비판에서 제외
  - SEC-6/7/8: 기존대로 유지
  - FIN-9: PM-3 방향으로 진행, 모델은 plan/critique=Opus 그대로 유지
  - FIN-10: 기존 유지 (동일 세션 내 단계 묶음 권장)
  - FIN-11: cautions.md를 CLAUDE.md에서 분리, `/se:learn audit` 호출 시에만 로드, 30일 후 archive ✅
  - FIN-12: review_report 압축 요약(Haiku 50줄 미만) + 원본 archive ✅
  - FIN-13: 분기 history 헤더(`SESSION_ID`, `START`) + 결정론 스크립트 `merge_history.py` ✅
  - FIN-14: 리스크 표 → `plan_risks.md` 분리, review/doc 단계에서만 로드 ✅
- **구조 변경 산출물**:
  - 신규: `_harness/security_engineer/plan/01.md ~ 10.md`, `_harness/security_engineer/plan_risks.md`
  - 갱신: `_harness/security_engineer/plan.md` (372줄 → 약 120줄), `commands/se/execute.md`, `commands/se/critique.md`
- **다음 단계**: `/se:execute` 로 2단계 (훅 보안 신뢰 루트) 진행 권장. 단, README.md 종합 갱신 후 진입 권장.

---

## 2026-04-25 — ECC 통합 v4 토큰 비용 비판 라운드 (`/se:critique`)

- **비판 대상**: plan.md (v4 확정본) — 사용자 호소 "토큰 소비량이 빠른 것 같아"
- **비판자 모델**: claude-opus-4-7
- **총평**: plan.md 372줄 + 매 단계 4파일 의무 로드 + Opus 반복 사용 + 모델 자동 전환에 의한 캐시 무효화가 토큰 폭증의 구조적 원인.
- **PM/PO 관점 비판**:
  1. plan.md 길이 상한 부재 — 무한 누적
  2. 매 단계 4파일 의무 로드 — 단계당 8~12K 토큰 고정 비용
  3. 격리 원칙 vs 토큰 효율 충돌 (비판 N회 = plan.md N번 풀 입력)
  4. `/se:backup` 빈도 캡 부재
  5. 신규 커맨드 4종 추가 비용
- **보안 관점 비판**:
  6. reviewer 서브에이전트 별도 컨텍스트 입력 중복
  7. extractor 매 결정마다 외부 출처 탐색 (LLM 호출 가정 시 폭증)
  8. `/se:summary` 짧은 세션 거부 정책 부재
- **재무 관점 비판**:
  9. Opus 4.7 단가(Sonnet의 약 5배) — plan/critique 반복 사용
  10. 모델 자동 전환 → 프롬프트 캐시 무효화
  11. cautions.md 자동 prepend → CLAUDE.md 부풀리기
  12. review_report/sbom_report 산출물 누적
  13. history 다중 세션 통합 시 입력 폭증
  14. 리스크 표 90줄 매 라운드 입력
- **수용 불가 항목**: 없음 (비기능 요구 — 사용자 결정 영역)
- **즉시 개선 권장**: plan/critique 중간 라운드 Sonnet + 최종 Opus, plan.md 슬라이싱, history 통합 결정론 스크립트, backup 빈도 캡
- **재계획 시 반드시 포함**: plan.md 슬라이싱 정책, 의무 로드 파일 축소표, 모델 사용 정책 갱신, 결정론 스크립트 vs LLM 명시, 산출물 누적 정책, 빈도 캡, 토큰 베이스라인 측정 재개
- **다음 단계**: 사용자 판단 → `/se:plan` 으로 토큰 절감 v5 재계획 또는 `/se:confirm` 으로 현 plan 유지

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

---

## 2026-04-26 — 하네스 구조 변경: 정의/산출물 경로 분리

- **진행 사항**:
  - 하네스 파일을 **글로벌 정의(read-only) ↔ 프로젝트별 산출물(read-write)** 두 계층으로 분리
  - **정의 파일**(절대경로 `/Users/pole/scripts/harness/harness/_harness/...`): 에이전트 시스템 프롬프트(`security_engineer/0X_*.md`, `student/0X_*.md`), `permissions.md`, `execute_library.md`
  - **산출물**(상대경로 `./_harness/...` — 현재 작업 디렉토리 기준): `history.md`, `plan.md`, `plan/`, `plan_risks.md`, `sbom_report.md`, `review_report.md`, `docs/` 등
  - 수정한 파일 (총 14개):
    - `CLAUDE.md` — "공통 지침 #4 파일 위치"에 정의/산출물 분리 규칙 추가, 보안엔지니어/학부생 페르소나 표의 파일 경로를 절대/상대 분리 표기
    - `commands/se/{critique,confirm,execute,review,doc}.md` — 산출물 경로를 `./_harness/...` 로 변경
    - `commands/teacher/doc.md` — 산출물 경로를 `./_harness/...` 로 변경
    - `_harness/security_engineer/{01_plan,02_critique,03_execute,04_review,05_document}.md` — 산출물 표기 변경, `execute_library.md` 참조는 절대경로 유지
    - `_harness/student/02_document.md` — 학습 문서 저장 위치 변경
    - `_harness/permissions.md` — 표 안 산출물 경로 표기 변경 + 상단 경로 규약 명시
  - **중앙화 옵션**: `/se:doc --central` 및 `/teacher:doc` 학부생 모드에서 글로벌 `docs/central/` 으로 수합 가능 — 여러 프로젝트의 산출물을 한 곳에서 보고 싶을 때 사용
- **이슈**:
  - 기존 글로벌 `_harness/` 안에 누적된 산출물(`history.md`, `plan.md`, `plan/`, `plan_risks.md`, `review_report.md`)은 그대로 유지 — 새 프로젝트부터 신규 규칙 적용
  - `safe_write.py` 가 향후 도입되면 CWD 기준 경로 해석 로직 필요 (3단계 후 구현 예정)
- **조치**:
  - 모든 슬래시 커맨드/페르소나 정의에서 산출물 경로를 `./_harness/...` 로 통일
  - CLAUDE.md 공통 지침에 "디렉토리가 없으면 자동 생성" 명시
- **미결 사항 / 개선 포인트**:
  - `safe_write.py` 구현 시 CWD 기준 경로 처리 검증 필요
  - 중앙화 모드 사용 흐름(`docs/central/` 네이밍 규칙 등) 실제 운영 후 다듬을 것
  - "프로젝트 루트" 기준이 항상 CWD라서 하위 디렉토리에서 슬래시 커맨드 실행 시 산출물이 흩어질 가능성 — 필요 시 git 루트 자동 탐지 도입 검토
