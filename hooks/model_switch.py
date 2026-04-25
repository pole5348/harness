#!/usr/bin/env python3
"""
UserPromptSubmit 훅 — 슬래시 커맨드에 따라 ~/.claude/settings.json 의 모델을 자동 전환한다.

/se:plan, /se:critique  → claude-opus-4-7
/se:confirm, /se:execute, /se:review → claude-sonnet-4-6
/se:doc                 → claude-haiku-4-5-20251001
/teacher:ask, /teacher:doc → claude-sonnet-4-6
"""
import json
import sys
import os
import re

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")

MODEL_MAP = [
    (r"/se:(plan|critique)", "claude-opus-4-7"),
    (r"/se:(confirm|execute|review)", "claude-sonnet-4-6"),
    (r"/se:doc", "claude-haiku-4-5-20251001"),
    (r"/teacher:(ask|doc)", "claude-sonnet-4-6"),
]

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
