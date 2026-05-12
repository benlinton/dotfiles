#!/usr/bin/env python3
"""Show brew packages, casks, and apps not declared in the macOS Ansible playbook."""

import json
import re
import subprocess
import sys
from pathlib import Path

PLAYBOOK = Path.home() / ".bootstrap" / "provision-workstation-macos.yml"
APP_DIRS = [Path("/Applications"), Path.home() / "Applications"]

MODULE_RE = re.compile(r"^(\s+)(community\.general\.homebrew(?:_cask)?):\s*$")
SCALAR_NAME_RE = re.compile(r"^\s+name:\s*(\S+)\s*$")
LIST_ITEM_RE = re.compile(r"^\s+-\s+(\S+)")


def parse_playbook(path: Path) -> tuple[set[str], set[str]]:
    """Walk the playbook line-by-line, pulling names out of homebrew/homebrew_cask tasks."""
    formulas: set[str] = set()
    casks: set[str] = set()
    lines = path.read_text().splitlines()
    i = 0
    while i < len(lines):
        m = MODULE_RE.match(lines[i])
        if not m:
            i += 1
            continue
        base_indent = len(m.group(1))
        bucket = casks if m.group(2).endswith("_cask") else formulas
        i += 1
        # Consume the module's args block (lines indented deeper than the module key).
        while i < len(lines):
            line = lines[i]
            if not line.strip():
                i += 1
                continue
            indent = len(line) - len(line.lstrip())
            if indent <= base_indent:
                break
            scalar = SCALAR_NAME_RE.match(line)
            if scalar and line.strip().startswith("name:"):
                bucket.add(scalar.group(1))
                i += 1
                continue
            if line.strip() == "name:":
                i += 1
                # Collect list items until the indentation drops back.
                while i < len(lines):
                    item = LIST_ITEM_RE.match(lines[i])
                    if not item:
                        break
                    bucket.add(item.group(1))
                    i += 1
                continue
            i += 1
    return formulas, casks


def run(cmd: list[str]) -> str:
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


def cask_app_artifacts(casks: set[str]) -> set[str]:
    if not casks:
        return set()
    info = json.loads(run(["brew", "info", "--cask", "--json=v2", *sorted(casks)]))
    apps: set[str] = set()
    for cask in info.get("casks", []):
        cask_apps: set[str] = set()
        for artifact in cask.get("artifacts") or []:
            entries = artifact.get("app") if isinstance(artifact, dict) else None
            if not entries:
                continue
            for entry in entries:
                if isinstance(entry, str):
                    cask_apps.add(Path(entry).name)
                elif isinstance(entry, dict) and "target" in entry:
                    cask_apps.add(Path(entry["target"]).name)
        # pkg-style casks (e.g. tailscale-app) have no `app` artifact — fall back
        # to the cask's human-readable name, which usually matches the bundle on disk.
        if not cask_apps:
            for name in cask.get("name") or []:
                cask_apps.add(f"{name}.app")
        apps.update(cask_apps)
    return apps


def section(title: str, items: list[str]) -> None:
    print(f"\n== {title} ({len(items)}) ==")
    for item in items:
        print(f"  {item}")


def main() -> int:
    if not PLAYBOOK.exists():
        print(f"Playbook not found: {PLAYBOOK}", file=sys.stderr)
        return 1

    managed_formulas, managed_casks = parse_playbook(PLAYBOOK)
    installed_formulas = set(run(["brew", "leaves"]).split())
    installed_casks = set(run(["brew", "list", "--cask"]).split())
    cask_apps = cask_app_artifacts(installed_casks)

    installed_apps: set[str] = set()
    for d in APP_DIRS:
        if d.is_dir():
            installed_apps.update(p.name for p in d.glob("*.app"))

    section("Unmanaged brew formulas", sorted(installed_formulas - managed_formulas))
    section("Unmanaged brew casks", sorted(installed_casks - managed_casks))
    section("Unmanaged apps", sorted(installed_apps - cask_apps))
    return 0


if __name__ == "__main__":
    sys.exit(main())
