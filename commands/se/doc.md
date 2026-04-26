---
description: "보안엔지니어 5단계: 문서화. 사용법: /se:doc [A=내부기술문서 B=외부보안리포트 C=Confluence D=PPT]"
model: claude-haiku-4-5-20251001
---

/Users/pole/scripts/harness/harness/_harness/security_engineer/05_document.md (글로벌 정의 파일) 을 읽고 해당 에이전트 역할과 출력 형식을 따른다.

문서 유형: $ARGUMENTS
인자가 없으면 사용자에게 A/B/C/D 중 선택을 요청한다.
인자에 `--central` 플래그가 포함되면 **중앙화 모드**(아래)로 동작한다.

## 입력

- `./_harness/security_engineer/review_report.md` 와 `./_harness/security_engineer/plan.md` (현재 프로젝트의 산출물) 을 함께 참조하여 작성한다.
- 산출물이 누락되어 있으면 사용자에게 위치를 확인한다.

## 산출물 저장 위치

- **기본 (프로젝트 로컬)**: `./_harness/security_engineer/docs/` 하위에 저장.
- **중앙화 모드 (`--central` 또는 사용자가 여러 프로젝트의 산출물을 한 곳에 모으도록 요청한 경우)**:
  - 글로벌 위치 `/Users/pole/scripts/harness/harness/_harness/security_engineer/docs/central/` 에 `[YYYY-MM-DD]_[프로젝트명]_[문서유형].md` 형식으로 저장한다.
  - 작성 전, 사용자에게 어느 프로젝트들의 산출물을 수합할지 확인한다.
