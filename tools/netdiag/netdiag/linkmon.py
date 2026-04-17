"""Link state polling (MediaConnectionState via PowerShell)."""

from __future__ import annotations

import json
import time
from typing import Any, Callable

from netdiag.util import run_powershell


def get_link_state(adapter_name: str) -> dict[str, Any]:
    safe = adapter_name.replace("'", "''")
    script = rf"""
$ErrorActionPreference = 'Stop'
$a = Get-NetAdapter -Name '{safe}' -ErrorAction Stop
[pscustomobject]@{{
    Name = $a.Name
    Status = $a.Status.ToString()
    MediaConnectionState = $a.MediaConnectionState.ToString()
    LinkSpeed = $a.LinkSpeed
}} | ConvertTo-Json -Compress
"""
    raw = run_powershell(script, timeout=30).strip()
    return json.loads(raw)


def monitor_link(
    adapter_name: str,
    poll_seconds: float = 1.0,
    max_cycles: int | None = None,
    on_link_up: Callable[[], None] | None = None,
) -> list[dict[str, Any]]:
    """Poll until max_cycles or forever; record transitions.

    Calls on_link_up when the link becomes connected.
    """
    events: list[dict[str, Any]] = []
    prev_media: str | None = None
    cycles = 0
    while True:
        try:
            st = get_link_state(adapter_name)
        except Exception as e:
            events.append({"error": str(e), "t": time.time()})
            time.sleep(poll_seconds)
            cycles += 1
            if max_cycles is not None and cycles >= max_cycles:
                break
            continue
        media = str(st.get("MediaConnectionState") or "")
        if prev_media and prev_media != media:
            events.append(
                {
                    "transition": f"{prev_media} -> {media}",
                    "detail": st,
                    "t": time.time(),
                }
            )
            if (
                media.lower() == "connected"
                and prev_media.lower() != "connected"
            ):
                if on_link_up:
                    on_link_up()
        elif prev_media is None:
            events.append({"initial": st, "t": time.time()})
        prev_media = media
        time.sleep(poll_seconds)
        cycles += 1
        if max_cycles is not None and cycles >= max_cycles:
            break
    return events
