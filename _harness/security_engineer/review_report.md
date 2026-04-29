# 검토 리포트: ECC 통합 v4 — 1단계 환경 정리

## 검토 일시: 2026-04-25
## 검토자 모델: claude-sonnet-4-6

---

## 1. 사용 가이드

### 이 단계의 목적
Claude Code 하네스 엔지니어링 레포의 환경 기반을 정비하는 1단계 완료분 검토.
신규 슬래시 커맨드(`/se:learn`, `/se:backup`, `/se:summary`, `/se:note`)의 모델 전환 훅을 선행 등록하고,
시크릿 관리 골격(`.env.example`, `.gitignore`)과 보안 정책 결정을 문서화했다.

### 초기 설정 방법
```bash
# 심볼릭 링크 (이미 완료)
ln -s C:/Users/tngus/OneDrive/바탕 화면/scripts/harness/CLAUDE.md ~/.claude/CLAUDE.md
ln -s C:/Users/tngus/OneDrive/바탕 화면/scripts/harness/hooks/model_switch.py ~/.claude/hooks/model_switch.py
ln -s C:/Users/tngus/OneDrive/바탕 화면/scripts/harness/commands/se ~/.claude/commands/se
ln -s C:/Users/tngus/OneDrive/바탕 화면/scripts/harness/commands/teacher ~/.claude/commands/teacher

# 프로젝트별 시크릿
cp .env.example _harness/projects/{프로젝트명}/.env
# → 실제 값 채운 후 사용. Git에 절대 커밋하지 않음.
```

### 일반 사용 시나리오
1. `/se:plan` → `/se:critique` → `/se:confirm` → `/se:execute` 순서로 진행
2. 세션 종료 시 `/se:backup`으로 진행 상태 스냅샷 저장 (4단계 구현 후)
3. 결론·판단을 마킹할 때 `/se:note decision <내용>` 사용 (9단계 구현 후)
4. Continuous Learning 검토 시 `/se:learn sonnet` 또는 `/se:learn opus` (9단계 구현 후)

---

## 2. 유지보수 포인트

| 항목 | 주기 | 담당 |
|---|---|---|
| `hooks/model_switch.py` 신규 커맨드 추가 | 새 커맨드 등록 시마다 | Claude + 사용자 |
| `settings.json` 훅 경로 확인 | `/usr/bin/python3` 경로 변경 시 | 사용자 |
| `.env.example` 슬롯 갱신 | 새 시크릿 항목 생성 시 | Claude + 사용자 |
| GPG 도입 재검토 | 7일 운영 무사고 후 (10단계 이후) | 사용자 결정 |
| `_harness/permissions.md` Python 경로 항목 | Python 버전 업그레이드 시 | 사용자 |

---

## 3. 아키텍처 개요

```
[사용자 입력 /se:* or /teacher:*]
        │
        ▼
[UserPromptSubmit Hook]
  ~/.claude/hooks/model_switch.py  ← 심볼릭 링크
        │  패턴 매칭
        │  일치: settings.json model 갱신 → continue
        │  /se:learn 인자 누락: block + 사용법 안내
        ▼
[~/.claude/settings.json]  ← model 필드 동적 갱신
        │
        ▼
[Claude Code] — 갱신된 model로 커맨드 실행
        │
        ├─ commands/se/*.md   (보안 엔지니어 커맨드)
        └─ commands/teacher/*.md  (학부생 커맨드)

시크릿 관리 (현재 골격, 3단계 구현 전):
  .env.example (Git 추적, 값 없음)
        │ 복사
        ▼
  _harness/projects/{프로젝트명}/.env  ← .gitignore 강제 제외
```

---

## 4. API 키 / 시크릿 목록

| 키 이름 | 용도 | 저장 위치 | 교체 주기 |
|---|---|---|---|
| (1단계 해당 없음) | — | — | — |

> 1단계 산출물에서 실제 시크릿 값 사용 없음. `.env.example`은 슬롯만 정의.
> 3단계 `safe_write.py` 구현 후 동적 마스킹 패턴 자동 등록 예정.

---

## 5. 보안 취약점

### Critical
없음

### High
없음

### Medium

#### M-1: `model_switch.py` shebang이 env 탐색 방식 — permissions.md 정책 불일치
- **위치**: [hooks/model_switch.py](../../../hooks/model_switch.py) line 1
- **현재**: `#!/usr/bin/env python3`
- **정책**: `_harness/permissions.md` "모든 hooks/*.py shebang을 `/usr/bin/python3`으로 고정"
- **영향**: `env`가 `$PATH`에서 python3를 탐색하므로, 가상환경 또는 brew python이 우선 선택될 수 있음. 의도치 않은 파이썬 버전 실행 가능.
- **조치**: `#!/usr/bin/env python3` → `#!/usr/bin/python3` 로 변경 (2단계 시작 시 일괄 적용 권장)

#### M-2: `.gitignore` 일반 `.env.*` 패턴 미포함
- **위치**: [.gitignore](../../../.gitignore)
- **현재**: `.env.local`, `.env.*.local`, `_harness/projects/*/.env` 만 제외
- **영향**: `.env.production`, `.env.staging`, `.env.test` 등 관행적 명명 파일이 실수로 커밋될 수 있음
- **조치**: `.env.*` 패턴 추가 (단, `.env.example`은 명시 허용 추가 필요)

### Low

#### L-1: 신규 커맨드 파일 미생성 상태에서 model_switch.py 매핑 선행 등록
- **위치**: [hooks/model_switch.py](../../../hooks/model_switch.py) — `/se:backup`, `/se:summary`, `/se:note`, `/se:learn`
- **영향**: 사용자가 실수로 이 커맨드를 호출하면 커맨드 파일 없음 오류 발생. 모델만 전환되고 아무 동작 안 함.
- **완화**: 향후 단계(4, 5, 9단계)에서 각 파일 생성 예정. 현재는 README에 "구현 예정" 표기로 충분.

#### L-2: `settings.json` 쓰기 원자성 없음
- **위치**: [hooks/model_switch.py](../../../hooks/model_switch.py) `save_settings()` 함수
- **현재**: `json.dump()`로 직접 쓰기 (덮어쓰기)
- **영향**: 동시에 두 개의 훅 인스턴스가 settings.json을 쓰면 파일 손상 가능. 단일 사용자 환경에서는 가능성 낮음.
- **완화 (선택)**: `tempfile` + `os.rename()` 원자적 치환 방식으로 교체 (2단계 self-check 추가 시 함께 고려)

### Low / Info

#### I-1: `~/.claude/commands/teacher` 심볼릭 링크 존재 여부 미검증
- README.md 설정 섹션에 심볼릭 링크 명령이 안내되어 있으나 현재 세션에서 실제 존재 확인 누락.
- 이미 설정되어 있다면 무해. 미설정이면 `/teacher:ask`, `/teacher:doc` 불동작.

#### I-2: obsidian 원격 브랜치 삭제 미완료
- 사용자가 직접 처리 예정. `.claudian/` 디렉토리 등 Obsidian 관련 파일만 포함 — 현 main/ecc-integration 브랜치에 영향 없음.

#### I-3: 외부 라이브러리 미사용 — SBOM 해당 없음
- 1단계 전체 표준 라이브러리만 사용 (`json`, `sys`, `os`, `re`). CVE/라이선스 이슈 없음.

---

## 6. SBOM 요약

> 1단계 산출물에 외부 의존성 없음 — 전량 Python 표준 라이브러리.

| 라이브러리 | 버전 | 출처 | CVE | 라이선스 |
|---|---|---|---|---|
| json | 내장 | Python 3.9.6 stdlib | 없음 | PSF |
| sys | 내장 | Python 3.9.6 stdlib | 없음 | PSF |
| os | 내장 | Python 3.9.6 stdlib | 없음 | PSF |
| re | 내장 | Python 3.9.6 stdlib | 없음 | PSF |

> 2단계 이후 `fcntl`, `hashlib` (stdlib), 9단계에서 `pyyaml` (외부) 도입 예정. pyyaml 도입 시 SBOM 갱신 필요.

---

## 종합 의견

1단계 산출물은 계획(plan.md) 대비 **대부분 충실하게 구현**됐다.
주요 목표인 python3 경로 고정, 신규 커맨드 매핑, 시크릿 관리 골격, GPG 미도입 결정 문서화가 모두 완료됐다.

**즉시 조치 권고 (2단계 시작 전)**:
1. **M-1** (Medium): `hooks/model_switch.py` shebang을 `#!/usr/bin/python3`으로 수정 — 2단계에서 모든 훅 파일 생성 시 일괄 적용하면 효율적.
2. **M-2** (Medium): `.gitignore`에 `.env.*` 추가 및 `!.env.example` 예외 추가.

**중장기 개선 권고**:
- **L-2**: `save_settings()` 원자적 쓰기 — 2단계 manifest self-check와 묶어서 처리.
- **I-1**: `~/.claude/commands/teacher` 심볼릭 링크 확인.

전반적으로 1단계는 **안정적으로 완료**됐으며 2단계 진입에 blockers 없음.
M-1, M-2는 간단한 수정이므로 2단계 시작 직전 또는 동시에 처리 권장.
