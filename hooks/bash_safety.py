#!/usr/bin/env python3
"""
PreToolUse 훅 — Bash 도구 호출 직전에 위험 패턴을 검사.

L4_block 패턴 매칭 시 {"decision":"block", "reason":"..."} 반환.
매칭 없으면 {"decision":"continue"} 반환.

stdin 입력 형식 (Claude Code 표준):
  {
    "tool_name": "Bash",
    "tool_input": {"command": "...", ...}
  }

패턴 정의: hooks/lib/bash_patterns.json
"""
import json
import os
import re
import sys

PATTERNS_PATH = os.path.join(
    os.path.dirname(os.path.realpath(__file__)),
    "lib",
    "bash_patterns.json",
)


def load_patterns():
    try:
        with open(PATTERNS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data.get("L4_block", [])
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print(json.dumps({"decision": "continue"}))
        return

    if data.get("tool_name") != "Bash":
        print(json.dumps({"decision": "continue"}))
        return

    command = data.get("tool_input", {}).get("command", "")
    if not command:
        print(json.dumps({"decision": "continue"}))
        return

    patterns = load_patterns()
    for entry in patterns:
        pattern = entry.get("pattern", "")
        reason = entry.get("reason", "위험 패턴")
        try:
            if re.search(pattern, command):
                print(json.dumps({
                    "decision": "block",
                    "reason": (
                        f"[bash_safety L4 차단] {reason}\n"
                        f"- 매칭 패턴: {pattern}\n"
                        f"- 명령: {command}\n"
                        f"진행하려면 정말로 의도한 것인지 사용자와 확인 후 명령을 변형하거나 분리해서 실행하세요."
                    ),
                }, ensure_ascii=False))
                return
        except re.error:
            continue

    print(json.dumps({"decision": "continue"}))


if __name__ == "__main__":
    main()
