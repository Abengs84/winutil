"""Diff two JSON snapshots."""

from __future__ import annotations

from typing import Any


def _flatten(prefix: str, obj: Any, out: dict[str, Any]) -> None:
    if isinstance(obj, dict):
        for k, v in sorted(obj.items()):
            _flatten(f"{prefix}.{k}" if prefix else str(k), v, out)
    elif isinstance(obj, list):
        out[prefix] = obj
    else:
        out[prefix] = obj


def diff_snapshots(a: dict[str, Any], b: dict[str, Any]) -> dict[str, Any]:
    fa: dict[str, Any] = {}
    fb: dict[str, Any] = {}
    _flatten("", a, fa)
    _flatten("", b, fb)
    keys = sorted(set(fa.keys()) | set(fb.keys()))
    changed: list[dict[str, Any]] = []
    for k in keys:
        va = fa.get(k)
        vb = fb.get(k)
        if va != vb:
            changed.append({"path": k or "(root)", "before": va, "after": vb})
    return {
        "paths_compared": len(keys),
        "differences": changed,
    }


def print_diff(report: dict[str, Any]) -> None:
    diffs = report.get("differences") or []
    n = len(diffs)
    scanned = report.get("paths_compared")
    print(f"Differences: {n} (paths scanned: {scanned})")
    print("-" * 60)
    for row in diffs:
        path = row["path"]
        print(f"  {path}")
        print(f"    - {row['before']!r}")
        print(f"    +  {row['after']!r}")
    print("-" * 60)
