"""DHCP release/renew and result parsing."""

from __future__ import annotations

import re
import time
from typing import Any

from netdiag.util import is_apipa, run_cmd


def parse_ipconfig_adapter_block(
    ipconfig_text: str,
    adapter_name: str,
) -> dict[str, Any]:
    """Extract IPv4, subnet, gateway, DHCP server from ipconfig /all.

    Parses one adapter section.
    """
    lines = ipconfig_text.replace("\r\n", "\n").split("\n")
    in_section = False
    section_lines: list[str] = []
    # e.g. "Ethernet adapter Ethernet:" (localized builds vary)
    name_pat = re.compile(
        r".*adapter\s+(.+?):\s*$",
        re.I,
    )
    for line in lines:
        m = name_pat.match(line.strip())
        if m:
            if in_section:
                break
            sec_name = m.group(1).strip().rstrip(":")
            if sec_name.lower() == adapter_name.lower():
                in_section = True
            continue
        if in_section:
            if line.strip() == "":
                break
            section_lines.append(line)
    text = "\n".join(section_lines)
    out: dict[str, Any] = {
        "adapter": adapter_name,
        "ipv4": None,
        "subnet": None,
        "gateway": None,
        "dhcp_enabled": None,
        "dhcp_server": None,
        "lease_obtained": None,
        "lease_expires": None,
    }
    v4 = re.search(r"IPv4 Address[ .]*:\s*([0-9.]+)", text, re.I)
    if v4:
        out["ipv4"] = v4.group(1).strip()
    sub = re.search(r"Subnet Mask[ .]*:\s*([0-9.]+)", text, re.I)
    if sub:
        out["subnet"] = sub.group(1).strip()
    gw = re.search(r"Default Gateway[ .]*:\s*([0-9.]+)", text, re.I)
    if gw:
        out["gateway"] = gw.group(1).strip()
    dhcpe = re.search(r"DHCP Enabled[ .]*:\s*(\w+)", text, re.I)
    if dhcpe:
        out["dhcp_enabled"] = dhcpe.group(1).strip().lower() == "yes"
    dhs = re.search(r"DHCP Server[ .]*:\s*([0-9.]+)", text, re.I)
    if dhs:
        out["dhcp_server"] = dhs.group(1).strip()
    lo = re.search(r"Lease Obtained[ .]*:\s*(.+)", text, re.I)
    if lo:
        out["lease_obtained"] = lo.group(1).strip()
    le = re.search(r"Lease Expires[ .]*:\s*(.+)", text, re.I)
    if le:
        out["lease_expires"] = le.group(1).strip()
    return out


def dhcp_renew(adapter_name: str) -> dict[str, Any]:
    """Release then renew; measure elapsed time; parse outcome."""
    t0 = time.monotonic()
    r_rel = run_cmd(["ipconfig", "/release", adapter_name], timeout=120)
    r_ren = run_cmd(["ipconfig", "/renew", adapter_name], timeout=120)
    elapsed = round(time.monotonic() - t0, 3)
    ip_all = run_cmd(["ipconfig", "/all"], timeout=60).stdout or ""
    parsed = parse_ipconfig_adapter_block(ip_all, adapter_name)
    ipv4 = parsed.get("ipv4")
    failure = False
    reason: str | None = None
    if not ipv4:
        failure = True
        reason = "No IPv4 address after renew"
    elif ipv4 and is_apipa(ipv4):
        failure = True
        reason = f"APIPA address {ipv4} (no DHCP lease)"
    return {
        "adapter": adapter_name,
        "seconds_elapsed": elapsed,
        "release_exit": r_rel.returncode,
        "renew_exit": r_ren.returncode,
        "release_stderr": (r_rel.stderr or "").strip(),
        "renew_stderr": (r_ren.stderr or "").strip(),
        "parsed": parsed,
        "failure": failure,
        "failure_reason": reason,
    }
