"""Collect NIC and system information via PowerShell + ipconfig."""

from __future__ import annotations

import json
import platform
import socket
from datetime import datetime, timezone
from typing import Any

from netdiag import __version__
from netdiag.util import run_cmd, run_powershell


def _ps_json(script: str) -> Any:
    raw = run_powershell(script, timeout=120)
    raw = raw.strip()
    if not raw:
        return None
    return json.loads(raw)


def collect_adapters() -> list[dict[str, Any]]:
    script = r"""
$ErrorActionPreference = 'Stop'
Get-NetAdapter | Select-Object `
    Name, InterfaceDescription, InterfaceGuid, Status, LinkSpeed, `
    MacAddress, MediaType, PhysicalMediaType, AdminStatus, `
    MediaConnectionState, DriverInformation, ifIndex, Virtual |
    ConvertTo-Json -Depth 6 -Compress
"""
    data = _ps_json(script)
    if data is None:
        return []
    if isinstance(data, dict):
        return [data]
    return list(data)


def collect_advanced_properties(
    adapter_name: str | None = None,
) -> list[dict[str, Any]]:
    filt = ""
    if adapter_name:
        safe = adapter_name.replace("'", "''")
        filt = f" -Name '{safe}'"
    script = rf"""
$ErrorActionPreference = 'SilentlyContinue'
Get-NetAdapterAdvancedProperty{filt} |
    Select-Object `
        Name, DisplayName, DisplayValue, ValidDisplayValues, `
        RegistryKeyword, RegistryValue |
    ConvertTo-Json -Depth 4 -Compress
"""
    data = _ps_json(script)
    if data is None:
        return []
    if isinstance(data, dict):
        return [data]
    return list(data)


def ipconfig_all() -> str:
    r = run_cmd(["ipconfig", "/all"], timeout=60)
    return (r.stdout or "") + (r.stderr or "")


def default_up_adapter_name(adapters: list[dict[str, Any]]) -> str | None:
    for row in adapters:
        st = str(row.get("Status") or "").lower()
        if st == "up":
            name = row.get("Name")
            if name:
                return str(name)
    for row in adapters:
        name = row.get("Name")
        if name:
            return str(name)
    return None


def build_snapshot(
    adapter_name: str | None = None,
    include_advanced: bool = True,
) -> dict[str, Any]:
    adapters = collect_adapters()
    target = adapter_name or default_up_adapter_name(adapters)
    adv: list[dict[str, Any]] = []
    if include_advanced:
        try:
            adv = collect_advanced_properties(target)
        except Exception:
            adv = collect_advanced_properties(None)

    return {
        "meta": {
            "tool_version": __version__,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "hostname": socket.gethostname(),
            "platform": platform.platform(),
            "selected_adapter": target,
        },
        "adapters": adapters,
        "advanced_properties": adv,
        "ipconfig_all": ipconfig_all(),
    }
