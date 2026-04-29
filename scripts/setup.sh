#!/usr/bin/env bash
# 하네스를 ~/.claude/ 에 연결한다 (macOS / Linux).
# 디렉토리/파일 모두 symlink 사용. 일반 사용자 권한으로 실행 가능.
#
# 사용법:
#   $ cd <harness 레포 경로>
#   $ ./scripts/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== 하네스 → ~/.claude/ 연결 ==="
echo "Harness Root: $HARNESS_ROOT"
echo "Claude Dir  : $CLAUDE_DIR"
echo

# 1. ~/.claude/ 및 하위 디렉토리 보장
mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/hooks"

# 2. symlink 생성 헬퍼
make_symlink() {
    local link="$1"
    local target="$2"

    if [ -L "$link" ] || [ -e "$link" ]; then
        echo "[skip] 이미 존재: $link"
        return 0
    fi
    if [ ! -e "$target" ]; then
        echo "[warn] target 없음: $target"
        return 0
    fi
    ln -s "$target" "$link"
    echo "[link] $link -> $target"
}

# 3. 디렉토리 symlink
make_symlink "$CLAUDE_DIR/commands/harness" "$HARNESS_ROOT/commands/harness"
make_symlink "$CLAUDE_DIR/commands/teacher" "$HARNESS_ROOT/commands/teacher"
make_symlink "$CLAUDE_DIR/_harness"         "$HARNESS_ROOT/_harness"
make_symlink "$CLAUDE_DIR/rules"            "$HARNESS_ROOT/rules"
make_symlink "$CLAUDE_DIR/hooks/lib"        "$HARNESS_ROOT/hooks/lib"

# 4. 파일 symlink
make_symlink "$CLAUDE_DIR/CLAUDE.md"                "$HARNESS_ROOT/CLAUDE.md"
make_symlink "$CLAUDE_DIR/hooks/model_switch.py"    "$HARNESS_ROOT/hooks/model_switch.py"
make_symlink "$CLAUDE_DIR/hooks/bash_safety.py"     "$HARNESS_ROOT/hooks/bash_safety.py"
make_symlink "$CLAUDE_DIR/hooks/stop_validate.py"   "$HARNESS_ROOT/hooks/stop_validate.py"

# 5. settings.json 다중 훅 등록 (idempotent)
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

/usr/bin/env python3 - <<PY
import json
import os
from pathlib import Path

settings_path = Path(os.path.expanduser("$SETTINGS_PATH"))
claude_dir = os.path.expanduser("$CLAUDE_DIR")

def hook_cmd(script):
    return f"/usr/bin/python3 {claude_dir}/hooks/{script}"

# (event, matcher, script)
registry = [
    ("UserPromptSubmit", None,   "model_switch.py"),
    ("PreToolUse",       "Bash", "bash_safety.py"),
    ("Stop",             None,   "stop_validate.py"),
]

if settings_path.exists():
    try:
        settings = json.loads(settings_path.read_text(encoding="utf-8"))
    except Exception:
        settings = {}
else:
    settings = {}

settings.setdefault("hooks", {})

for event, matcher, script in registry:
    if not (Path(claude_dir) / "hooks" / script).exists():
        print(f"[skip] {event} hook ({script}) not deployed yet")
        continue

    settings["hooks"].setdefault(event, [])

    already = False
    for block in settings["hooks"][event]:
        for h in block.get("hooks", []):
            if script in h.get("command", ""):
                already = True
                break
        if already:
            break

    if already:
        print(f"[skip] {event} hook already registered ({script})")
        continue

    block = {"hooks": [{"type": "command", "command": hook_cmd(script)}]}
    if matcher:
        block["matcher"] = matcher
    settings["hooks"][event].append(block)
    print(f"[update] {event} hook registered ({script})")

settings_path.write_text(
    json.dumps(settings, ensure_ascii=False, indent=2),
    encoding="utf-8"
)
PY

echo
echo "=== 설치 검증 ==="
for path in \
    "CLAUDE.md" \
    "commands/harness/plan.md" \
    "_harness/security_engineer/01_plan.md" \
    "_harness/security_engineer/docs/templates/ADR.md" \
    "rules/common/karpathy_guidelines.md" \
    "hooks/model_switch.py" \
    "hooks/bash_safety.py" \
    "hooks/stop_validate.py"; do
    if [ -e "$CLAUDE_DIR/$path" ]; then
        echo "[ok]   ~/.claude/$path"
    else
        echo "[fail] ~/.claude/$path (누락)"
    fi
done

echo
echo "완료. 새 Claude Code 세션을 열어 /se:plan 등 슬래시 커맨드를 실행해보세요."
