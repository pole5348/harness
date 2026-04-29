#!/usr/bin/env python3
"""
Stop 훅 — Claude 세션 종료 시 프로젝트 자동 검증.

CWD 의 프로젝트 마커를 감지하여 적절한 검증 명령을 실행한다.
세션 동안 코드 변경이 없었으면 skip (git diff --quiet 로 판정).

검증 결과는 stderr 로 출력 → Claude UI 에 표시된다.
종료 코드 0 (검증 실패에도) — 정보 제공 목적, 차단하지 않음.

검증 매트릭스:
| 마커 파일 | 검증 명령 |
|---|---|
| package.json (npm)  | npm run lint --if-present && npm run build --if-present && npm test --if-present |
| pyproject.toml      | pytest -q (있으면) |
| Cargo.toml          | cargo check --quiet |
| go.mod              | go build ./... && go test ./... |
| (마커 없음)         | skip |
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def has_changes(cwd: Path) -> bool:
    """git 추적 변경이 있는지. 비-레포면 항상 True (skip 회피)."""
    if not (cwd / ".git").exists():
        return True
    try:
        result = subprocess.run(
            ["git", "diff", "--quiet"],
            cwd=str(cwd),
            timeout=5,
        )
        # exit 0 = no changes, 1 = has changes
        return result.returncode != 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return True


def run(cmd: list, cwd: Path) -> tuple[int, str]:
    """명령 실행. (exit_code, head_of_output) 반환."""
    try:
        result = subprocess.run(
            cmd,
            cwd=str(cwd),
            capture_output=True,
            text=True,
            timeout=120,
        )
        out = (result.stdout + result.stderr).strip()
        # 로그 폭증 방지 — 마지막 20줄만
        lines = out.splitlines()
        head = "\n".join(lines[-20:]) if lines else ""
        return result.returncode, head
    except subprocess.TimeoutExpired:
        return 124, "(timeout 120s)"
    except FileNotFoundError:
        return 127, "(command not found)"


def detect_and_run(cwd: Path) -> list[tuple[str, int, str]]:
    """마커별 검증 실행. [(label, exit, output), ...] 반환."""
    results = []

    if (cwd / "package.json").exists() and shutil.which("npm"):
        # 각 단계 분리 — 어느 단계 실패인지 보이도록
        for label, cmd in [
            ("npm lint",  ["npm", "run", "lint", "--if-present", "--silent"]),
            ("npm build", ["npm", "run", "build", "--if-present", "--silent"]),
            ("npm test",  ["npm", "test", "--if-present", "--silent"]),
        ]:
            code, out = run(cmd, cwd)
            results.append((label, code, out))
            if code != 0:
                break  # fail-fast

    elif (cwd / "pyproject.toml").exists() and shutil.which("pytest"):
        results.append(("pytest", *run(["pytest", "-q"], cwd)))

    elif (cwd / "Cargo.toml").exists() and shutil.which("cargo"):
        results.append(("cargo check", *run(["cargo", "check", "--quiet"], cwd)))
        if results[-1][1] == 0:
            results.append(("cargo test", *run(["cargo", "test", "--quiet"], cwd)))

    elif (cwd / "go.mod").exists() and shutil.which("go"):
        results.append(("go build", *run(["go", "build", "./..."], cwd)))
        if results[-1][1] == 0:
            results.append(("go test", *run(["go", "test", "./..."], cwd)))

    return results


def main():
    # stdin 무시 — Stop 훅은 컨텍스트 정보 별로 안 쓴다
    try:
        sys.stdin.read()
    except Exception:
        pass

    cwd = Path(os.getcwd())

    if not has_changes(cwd):
        # 변경 없음 — 검증 skip
        print(json.dumps({"decision": "continue"}))
        return

    results = detect_and_run(cwd)
    if not results:
        print(json.dumps({"decision": "continue"}))
        return

    lines = ["[stop_validate]"]
    overall_ok = True
    for label, code, out in results:
        tag = "OK " if code == 0 else "FAIL"
        lines.append(f"  [{tag}] {label} (exit {code})")
        if code != 0 and out:
            lines.append("  --- output (last 20 lines) ---")
            for ln in out.splitlines():
                lines.append(f"    {ln}")
            overall_ok = False

    summary = "\n".join(lines)
    # stderr 로 출력 → Claude UI 에 표시
    print(summary, file=sys.stderr)

    # 차단하지 않음 — 정보 전달만
    print(json.dumps({"decision": "continue"}))


if __name__ == "__main__":
    main()
