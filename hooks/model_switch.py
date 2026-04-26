#!/usr/bin/env python3
"""
UserPromptSubmit 훅 — 슬래시 커맨드에 따라 ~/.claude/settings.json 의 모델을 자동 전환한다.

/se:plan, /se:critique                          → claude-opus-4-7
/se:confirm, /se:execute, /se:review            → claude-sonnet-4-6
/se:doc                                         → claude-haiku-4-5-20251001
/se:learn sonnet|opus                           → 인자에 따라 모델 결정
/se:learn rollback|audit|cleanup                → claude-sonnet-4-6
/se:backup, /se:summary, /se:note               → claude-sonnet-4-6
/teacher:ask, /teacher:doc                      → claude-sonnet-4-6

/se:learn 인자 누락 시 → 사용자에게 모델 명시 요청 메시지를 additionalContext로 출력
"""
import json
import sys
import os
import re

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")

MODEL_MAP = [
    (r"/se:(plan|critique)", "claude-opus-4-7"),
    (r"/se:(confirm|execute|review)", "claude-sonnet-4-6"),
    (r"/se:doc\b", "claude-haiku-4-5-20251001"),
    (r"/se:learn\s+sonnet\b", "claude-sonnet-4-6"),
    (r"/se:learn\s+opus\b", "claude-opus-4-7"),
    (r"/se:learn\s+(rollback|audit|cleanup)\b", "claude-sonnet-4-6"),
    (r"/se:(backup|summary|note)\b", "claude-sonnet-4-6"),
    (r"/teacher:(ask|doc)", "claude-sonnet-4-6"),
]

LEARN_NO_ARG_MSG = (
    "/se:learn 인자가 없습니다. 사용할 모델을 명시해주세요:\n"
    "  /se:learn sonnet   — claude-sonnet-4-6 으로 전환 후 quarantine 검토\n"
    "  /se:learn opus     — claude-opus-4-7 으로 전환 후 quarantine 검토\n"
    "  /se:learn rollback <commit-hash>   — 이전 자동 반영 롤백\n"
    "  /se:learn audit    — 최근 1주일 자동 반영 점검\n"
    "  /se:learn cleanup  — 30일 만료 quarantine 아카이브"
)

def load_settings():
    try:
        with open(SETTINGS_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def save_settings(settings):
    with open(SETTINGS_PATH, "w") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)

def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print(json.dumps({"decision": "continue"}))
        return

    prompt = data.get("prompt", "")

    # /se:learn 인자 누락 감지 (/se:learn 뒤에 공백+문자가 없는 경우)
    if re.search(r"/se:learn(\s*$|\s+(?!sonnet|opus|rollback|audit|cleanup)\S)", prompt):
        print(json.dumps({
            "decision": "block",
            "reason": LEARN_NO_ARG_MSG,
        }))
        return

    target_model = None
    for pattern, model in MODEL_MAP:
        if re.search(pattern, prompt):
            target_model = model
            break

    if target_model:
        settings = load_settings()
        if settings.get("model") != target_model:
            settings["model"] = target_model
            save_settings(settings)

    print(json.dumps({"decision": "continue"}))

if __name__ == "__main__":
    main()
