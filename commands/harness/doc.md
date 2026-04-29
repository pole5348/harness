---
description: "보안엔지니어 5단계: 문서화. 사용법: /harness:doc [A=내부기술문서 B=외부보안리포트 C=Confluence D=PPT | ADR PRD ARCH UI]"
model: claude-haiku-4-5-20251001
---

~/.claude/_harness/security_engineer/05_document.md (글로벌 정의 파일) 을 읽고 해당 에이전트 역할과 출력 형식을 따른다.

문서 유형: $ARGUMENTS
인자가 없으면 사용자에게 유형(A/B/C/D 또는 ADR/PRD/ARCH/UI) 중 선택을 요청한다.
인자에 `--central` 플래그가 포함되면 **중앙화 모드**(아래)로 동작한다.

## 입력

- `./_harness/security_engineer/review_report.md` 와 `./_harness/security_engineer/plan.md` (현재 프로젝트의 산출물) 을 함께 참조하여 작성한다.
- 산출물이 누락되어 있으면 사용자에게 위치를 확인한다.

## 표준 템플릿 (v5.4 신규)

채널 유형(A/B/C/D)과 별개로, 문서 종류 중 하나를 지정하면 글로벌 템플릿을 기반으로 작성한다:

| 유형 | 의미 | 템플릿 (글로벌 정의) |
|---|---|---|
| `ADR` | Architecture Decision Record (의사결정 기록) | `~/.claude/_harness/security_engineer/docs/templates/ADR.md` |
| `PRD` | Product Requirements Document (요구사항 정의) | `~/.claude/_harness/security_engineer/docs/templates/PRD.md` |
| `ARCH` | Architecture Document (아키텍처 문서) | `~/.claude/_harness/security_engineer/docs/templates/ARCHITECTURE.md` |
| `UI` | UI / CLI / Output Guide | `~/.claude/_harness/security_engineer/docs/templates/UI_GUIDE.md` |

각 템플릿은 보안 엔지니어 페르소나에 특화된 항목 (위협 모델, 시크릿 처리, 검증 기준) 을 포함한다.
인자 형식: `/harness:doc ADR <결정 제목>` 또는 `/harness:doc PRD <기능명>` 등.

## 산출물 저장 위치

- **기본 (프로젝트 로컬)**: `./_harness/security_engineer/docs/` 하위에 저장.
  - 표준 템플릿 사용 시: `./_harness/security_engineer/docs/{ADR|PRD|ARCH|UI}/[YYYY-MM-DD]_[제목].md`
  - 채널 출력 (A/B/C/D) 사용 시: `./_harness/security_engineer/docs/[YYYY-MM-DD]_[유형]_[제목].md`
- **중앙화 모드 (`--central` 또는 사용자가 여러 프로젝트의 산출물을 한 곳에 모으도록 요청한 경우)**:
  - 글로벌 위치 `~/.claude/_harness/security_engineer/docs/central/` 에 `[YYYY-MM-DD]_[프로젝트명]_[문서유형].md` 형식으로 저장한다.
  - 작성 전, 사용자에게 어느 프로젝트들의 산출물을 수합할지 확인한다.
