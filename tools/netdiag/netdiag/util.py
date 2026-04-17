"""Shared helpers."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def run_powershell(script: str, timeout: int | None = 120) -> str:
    """Run a PowerShell script and return stdout (UTF-8)."""
    proc = subprocess.run(
        [
            "powershell.exe",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )
    if proc.returncode != 0:
        err = (proc.stderr or "").strip() or f"exit {proc.returncode}"
        raise RuntimeError(f"PowerShell failed: {err}")
    return proc.stdout


def run_cmd(
    args: list[str],
    timeout: int | None = 180,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, ensure_ascii=False))


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=2, ensure_ascii=False)
    path.write_text(text, encoding="utf-8")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def warn(msg: str) -> None:
    print(f"[!] {msg}", file=sys.stderr)


def info(msg: str) -> None:
    print(f"[*] {msg}", file=sys.stderr)


def is_apipa(ipv4: str) -> bool:
    return ipv4.startswith("169.254.")
