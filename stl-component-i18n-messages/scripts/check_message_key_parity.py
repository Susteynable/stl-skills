#!/usr/bin/env python3
"""Compare key sets across Stey message resource files.

Usage:
  check_message_key_parity.py <messages-dir>

Exits 0 when all messages* files define the same keys; 1 on mismatch.
Ignores blank lines and # comments.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def load_keys(path: Path) -> set[str]:
    keys: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if "=" not in stripped:
            print(f"WARN: skipping malformed line in {path.name}: {stripped}", file=sys.stderr)
            continue
        key = stripped.split("=", 1)[0].strip()
        if key:
            keys.add(key)
    return keys


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <messages-dir>", file=sys.stderr)
        return 2

    messages_dir = Path(sys.argv[1])
    if not messages_dir.is_dir():
        print(f"ERROR: not a directory: {messages_dir}", file=sys.stderr)
        return 2

    files = sorted(
        p for p in messages_dir.iterdir()
        if p.is_file() and re.match(r"^messages(\.[a-z]{2})?$", p.name)
    )
    if not files:
        print(f"ERROR: no messages* files in {messages_dir}", file=sys.stderr)
        return 2

    key_sets = {f.name: load_keys(f) for f in files}
    reference_name = "messages.en" if "messages.en" in key_sets else files[0].name
    reference_keys = key_sets[reference_name]

    ok = True
    for name, keys in sorted(key_sets.items()):
        if name == reference_name:
            continue
        missing = reference_keys - keys
        extra = keys - reference_keys
        if missing or extra:
            ok = False
            print(f"MISMATCH: {name} vs {reference_name}")
            if missing:
                print(f"  missing ({len(missing)}): {', '.join(sorted(missing)[:10])}"
                      + (" …" if len(missing) > 10 else ""))
            if extra:
                print(f"  extra ({len(extra)}): {', '.join(sorted(extra)[:10])}"
                      + (" …" if len(extra) > 10 else ""))

    if ok:
        print(f"OK: {len(files)} files, {len(reference_keys)} keys each (reference: {reference_name})")
        return 0

    print(f"ERROR: key parity failed ({len(files)} files, reference: {reference_name})", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
