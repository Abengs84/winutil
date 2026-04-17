"""Rule-based warnings for enterprise NIC / DHCP / VLAN scenarios."""

from __future__ import annotations

from typing import Any


def analyze_snapshot(snap: dict[str, Any]) -> list[str]:
    warnings: list[str] = []
    adapters = snap.get("adapters") or []
    for a in adapters:
        desc = str(a.get("InterfaceDescription") or "").lower()
        if "realtek" in desc:
            warnings.append(
                "Realtek NIC detected: some enterprise / dock / WoL "
                "combinations have known driver quirks; try OEM or Windows "
                "Update driver, disable power saving on the NIC, and verify "
                "switch port settings."
            )
    cap = snap.get("capture_summary") or {}
    if cap.get("skipped"):
        cap = {}
    vids = cap.get("vlan_ids") or []
    if vids:
        warnings.append(
            f"802.1Q VLAN tag(s) seen on client ({vids}): possible trunk / "
            "misconfigured access port, or hypervisor/team software - "
            "confirm expected VLAN with network team."
        )
    dhcp = snap.get("dhcp_test") or {}
    if dhcp.get("failure"):
        reason = dhcp.get("failure_reason") or "DHCP failure"
        warnings.append(f"DHCP issue: {reason}")
    # Link up but no DHCP / APIPA
    if dhcp.get("parsed"):
        ip = dhcp["parsed"].get("ipv4")
        if ip and str(ip).startswith("169.254."):
            warnings.append(
                "Link may be up but host has APIPA only - possible "
                "NIC/switch/VLAN/DHCP scope issue."
            )
    if cap.get("ok") and cap.get("packet_count", 0) > 0:
        if not cap.get("dhcp_offer_seen") and not cap.get("dhcp_ack_seen"):
            if dhcp.get("failure"):
                warnings.append(
                    "Pattern: capture saw traffic but no DHCP Offer/ACK; "
                    "combined with renew failure suggests DHCP unreachable, "
                    "blocked, or wrong VLAN."
                )
    # Dedup preserve order
    seen: set[str] = set()
    out: list[str] = []
    for w in warnings:
        if w not in seen:
            seen.add(w)
            out.append(w)
    return out
