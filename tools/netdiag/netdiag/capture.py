"""Packet capture: DHCP frames and 802.1Q VLAN tags (scapy, optional)."""

from __future__ import annotations

import importlib
from collections import Counter
from types import SimpleNamespace
from typing import Any

from netdiag.util import warn

# DHCP option53 message types
_DHCP_MSG_NAMES = {
    1: "discover",
    2: "offer",
    3: "request",
    4: "decline",
    5: "ack",
    6: "nak",
    7: "release",
    8: "inform",
}


def _try_import_scapy():
    try:
        scapy_all = importlib.import_module("scapy.all")
    except ImportError:
        return None
    sniff = scapy_all.sniff
    Ether = scapy_all.Ether
    Dot1Q = scapy_all.Dot1Q
    DHCP = scapy_all.DHCP
    return sniff, Ether, Dot1Q, DHCP


def resolve_scapy_iface(adapter_name: str | None) -> str | None:
    """Map Windows adapter name to scapy interface name."""
    try:
        win = importlib.import_module("scapy.arch.windows")
        get_windows_if_list = win.get_windows_if_list
    except ImportError:
        return None
    adapters = get_windows_if_list()
    if not adapter_name:
        return None
    an = adapter_name.lower()
    for row in adapters:
        name = (row.get("name") or "").lower()
        desc = (row.get("description") or "").lower()
        if an == name or an in desc or desc in an:
            return row.get("name")
    return None


def capture_summary(
    interface: str | None,
    seconds: float = 10.0,
) -> dict[str, Any]:
    mod = _try_import_scapy()
    if mod is None:
        warn(
            "scapy not installed. Run: pip install -r requirements.txt "
            "(Npcap required for capture)."
        )
        return {
            "ok": False,
            "error": "scapy_unavailable",
            "seconds": seconds,
        }
    sniff, Ether, Dot1Q, DHCP = mod  # type: ignore[misc]

    iface = interface or None
    if iface:
        iface = resolve_scapy_iface(iface) or iface

    dhcp_counts: Counter[str] = Counter()
    vlan_ids: set[int] = set()
    cap_state = SimpleNamespace(
        packet_count=0,
        dhcp_offer_seen=False,
        dhcp_ack_seen=False,
    )

    def handle(pkt: Any) -> None:
        cap_state.packet_count += 1
        try:
            if pkt.haslayer(Dot1Q):
                vlan_ids.add(int(pkt[Dot1Q].vlan))
        except Exception:
            pass
        try:
            if pkt.haslayer(DHCP):
                opts = pkt[DHCP].options
                for opt in opts:
                    if not isinstance(opt, tuple) or len(opt) < 2:
                        continue
                    if opt[0] != "message-type":
                        continue
                    mt = opt[1]
                    name = _DHCP_MSG_NAMES.get(int(mt), f"type_{mt}")
                    dhcp_counts[name] += 1
                    if name == "offer":
                        cap_state.dhcp_offer_seen = True
                    if name == "ack":
                        cap_state.dhcp_ack_seen = True
                    break
        except Exception:
            pass

    try:
        sniff(iface=iface, prn=handle, timeout=seconds, store=False)
    except Exception as e:
        return {
            "ok": False,
            "error": str(e),
            "seconds": seconds,
            "interface": iface,
        }

    lines = []
    if dhcp_counts:
        dhcp_parts = ", ".join(
            f"{k}={v}" for k, v in sorted(dhcp_counts.items())
        )
        lines.append("DHCP (BOOTP) message types seen: " + dhcp_parts)
    else:
        lines.append(
            "No DHCP Discover/Offer/Request/ACK frames parsed "
            "(may be normal if idle)."
        )

    if (
        not cap_state.dhcp_offer_seen
        and not cap_state.dhcp_ack_seen
        and cap_state.packet_count > 0
    ):
        lines.append("No DHCP Offer or ACK seen in capture window.")

    if vlan_ids:
        vlan_part = ", ".join(str(v) for v in sorted(vlan_ids))
        lines.append(f"VLAN tag(s) detected: {vlan_part}")
    else:
        lines.append(
            "No 802.1Q VLAN tags detected on captured frames "
            "(access port or no tagged traffic)."
        )

    return {
        "ok": True,
        "seconds": seconds,
        "interface": iface,
        "packet_count": cap_state.packet_count,
        "dhcp_message_counts": dict(dhcp_counts),
        "dhcp_offer_seen": cap_state.dhcp_offer_seen,
        "dhcp_ack_seen": cap_state.dhcp_ack_seen,
        "vlan_ids": sorted(vlan_ids),
        "summary_lines": lines,
    }


def print_capture_report(summary: dict[str, Any]) -> None:
    for line in summary.get("summary_lines") or []:
        print(line)
    if not summary.get("ok"):
        print(f"Capture failed: {summary.get('error', 'unknown')}")
