"""CLI entry for netdiag."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from netdiag import __version__
from netdiag.capture import capture_summary, print_capture_report
from netdiag.collect import build_snapshot, default_up_adapter_name
from netdiag.compare import diff_snapshots, print_diff
from netdiag.dhcp import dhcp_renew
from netdiag.heuristics import analyze_snapshot
from netdiag.linkmon import monitor_link
from netdiag.util import info, load_json, print_json, warn, write_json


def cmd_list_ifaces(_: argparse.Namespace) -> int:
    script = r"""
$ErrorActionPreference = 'Stop'
Get-NetAdapter | ForEach-Object {
    [pscustomobject]@{
        Name = $_.Name
        Status = $_.Status.ToString()
        MediaConnectionState = $_.MediaConnectionState.ToString()
        LinkSpeed = $_.LinkSpeed
        InterfaceDescription = $_.InterfaceDescription
    }
} | ConvertTo-Json -Depth 3 -Compress
"""
    from netdiag.util import run_powershell

    raw = run_powershell(script, timeout=60).strip()
    rows = json.loads(raw) if raw else []
    if isinstance(rows, dict):
        rows = [rows]
    for a in rows:
        print(
            f"{a.get('Name')}\t{a.get('Status')}\t"
            f"{a.get('MediaConnectionState')}\t"
            f"{a.get('InterfaceDescription')}"
        )
    return 0


def cmd_export(ns: argparse.Namespace) -> int:
    snap = build_snapshot(adapter_name=ns.interface)
    path = Path(ns.output)
    write_json(path, snap)
    info(f"Wrote {path}")
    return 0


def cmd_renew(ns: argparse.Namespace) -> int:
    snap = build_snapshot(adapter_name=ns.interface, include_advanced=False)
    adapters = snap["adapters"]
    name = ns.interface or default_up_adapter_name(adapters)
    if not name:
        warn("No adapter found.")
        return 1
    info(f"DHCP release/renew on '{name}' ...")
    result = dhcp_renew(name)
    print_json(result)
    if result.get("failure"):
        return 2
    return 0


def cmd_capture(ns: argparse.Namespace) -> int:
    snap = build_snapshot(adapter_name=ns.interface, include_advanced=False)
    adapters = snap["adapters"]
    iface = ns.interface or default_up_adapter_name(adapters)
    label = iface or "default"
    info(f"Capturing {ns.seconds}s on '{label}' (admin + Npcap required)...")
    summary = capture_summary(iface, seconds=float(ns.seconds))
    print_capture_report(summary)
    if ns.json_out:
        write_json(Path(ns.json_out), summary)
    ok = summary.get("ok") or summary.get("error") == "scapy_unavailable"
    return 0 if ok else 1


def cmd_compare(ns: argparse.Namespace) -> int:
    p1 = Path(ns.file1)
    p2 = Path(ns.file2)
    a = load_json(p1)
    b = load_json(p2)
    report = diff_snapshots(a, b)
    print_diff(report)
    if ns.json_out:
        write_json(Path(ns.json_out), report)
    return 0


def cmd_diagnose(ns: argparse.Namespace) -> int:
    info("Collecting system / NIC info ...")
    snap: dict[str, Any] = build_snapshot(adapter_name=ns.interface)
    name = snap["meta"]["selected_adapter"]
    if not name:
        warn("Could not pick an adapter.")
        return 1

    if not ns.skip_dhcp:
        info(f"DHCP renew on '{name}' ...")
        snap["dhcp_test"] = dhcp_renew(name)
    else:
        snap["dhcp_test"] = {"skipped": True}

    if ns.capture:
        info(f"Packet capture ({ns.capture_seconds}s) ...")
        snap["capture_summary"] = capture_summary(
            name, seconds=float(ns.capture_seconds)
        )
        print("\n--- Capture ---")
        print_capture_report(snap["capture_summary"])
    else:
        snap["capture_summary"] = {"skipped": True}

    snap["warnings"] = analyze_snapshot(snap)

    print("\n--- Warnings ---")
    for w in snap["warnings"]:
        print(f" * {w}")
    if not snap["warnings"]:
        print(" (none)")

    if ns.output:
        write_json(Path(ns.output), snap)
        info(f"Full snapshot: {ns.output}")

    print("\n--- Snapshot summary (JSON) ---")
    print_json(snap)
    if snap.get("dhcp_test") and snap["dhcp_test"].get("failure"):
        return 2
    return 0


def cmd_linkmon(ns: argparse.Namespace) -> int:
    snap = build_snapshot(adapter_name=ns.interface, include_advanced=False)
    adapters = snap["adapters"]
    name = ns.interface or default_up_adapter_name(adapters)
    if not name:
        return 1
    info(f"Monitoring link on '{name}' (Ctrl+C to stop) ...")

    def on_up() -> None:
        print("\n[link-up] Running DHCP renew + short capture ...")
        r = dhcp_renew(name)
        print_json(r)
        cap = capture_summary(name, seconds=float(ns.capture_seconds))
        print_capture_report(cap)

    try:
        max_c = ns.max_cycles if ns.max_cycles and ns.max_cycles > 0 else None
        events = monitor_link(
            name,
            poll_seconds=float(ns.interval),
            max_cycles=max_c,
            on_link_up=on_up if ns.on_link_up else None,
        )
        print_json(events)
    except KeyboardInterrupt:
        print("\nStopped.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="netdiag",
        description=(
            "Windows network diagnostics (DHCP, VLAN hints, NIC info). "
            "Run from tools/netdiag as: python -m netdiag"
        ),
    )
    p.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    sub = p.add_subparsers(dest="command", required=True)

    s = sub.add_parser(
        "diagnose",
        help="Collect info, optional DHCP renew + capture, heuristics",
    )
    s.add_argument("-i", "--interface", help="NetAdapter Name (e.g. Ethernet)")
    s.add_argument(
        "--skip-dhcp",
        action="store_true",
        help="Do not release/renew",
    )
    s.add_argument(
        "--capture",
        action="store_true",
        help="Run ~10s scapy capture (needs Npcap)",
    )
    s.add_argument("--capture-seconds", type=float, default=10.0)
    s.add_argument("-o", "--output", help="Write full JSON snapshot to file")
    s.set_defaults(func=cmd_diagnose)

    s = sub.add_parser("capture", help="Capture packets (scapy + Npcap)")
    s.add_argument("-i", "--interface", help="Adapter name")
    s.add_argument("-s", "--seconds", type=float, default=10.0)
    s.add_argument("--json-out", help="Write capture summary JSON")
    s.set_defaults(func=cmd_capture)

    s = sub.add_parser("renew", help="ipconfig /release + /renew on adapter")
    s.add_argument("-i", "--interface", help="Adapter name")
    s.set_defaults(func=cmd_renew)

    s = sub.add_parser("export", help="Export NIC snapshot JSON only")
    s.add_argument("-i", "--interface", help="Adapter name")
    s.add_argument("-o", "--output", required=True, help="Output .json path")
    s.set_defaults(func=cmd_export)

    s = sub.add_parser("compare", help="Diff two snapshot JSON files")
    s.add_argument("file1", type=str)
    s.add_argument("file2", type=str)
    s.add_argument("--json-out", help="Write diff report JSON")
    s.set_defaults(func=cmd_compare)

    s = sub.add_parser("list-ifaces", help="List Get-NetAdapter summary")
    s.set_defaults(func=cmd_list_ifaces)

    s = sub.add_parser(
        "linkmon",
        help="Poll link state; optional DHCP+capture on link-up",
    )
    s.add_argument("-i", "--interface", help="Adapter name")
    s.add_argument("--interval", type=float, default=1.0)
    s.add_argument(
        "--max-cycles",
        type=int,
        default=0,
        help="Stop after N polls (0 = until Ctrl+C)",
    )
    s.add_argument(
        "--on-link-up",
        action="store_true",
        help="On Connected: renew DHCP and capture",
    )
    s.add_argument("--capture-seconds", type=float, default=10.0)
    s.set_defaults(func=cmd_linkmon)

    return p


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    parser = build_parser()
    ns = parser.parse_args(argv)
    return int(ns.func(ns))
