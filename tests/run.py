#!/usr/bin/env python3
"""Runs tests/shared.spec.luau against the pure modules in src/shared.

Needs the `luau` CLI on PATH (e.g. `cargo install luau-cli`). Shared modules are bundled into one
script with minimal Roblox stubs (tests/prelude.luau), so only Instance-free code can be tested.
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SHARED = os.path.join(HERE, "..", "src", "shared")


def bundle() -> str:
    parts = [open(os.path.join(HERE, "prelude.luau")).read()]
    for folder, _, files in os.walk(SHARED):
        for name in sorted(files):
            if not name.endswith(".luau"):
                continue
            path = os.path.join(folder, name)
            module = "Shared." + os.path.relpath(path, SHARED)[: -len(".luau")].replace(os.sep, ".")
            # Modules are wrapped in functions, where `export type` isn't allowed.
            source = re.sub(r"^export type", "type", open(path).read(), flags=re.M)
            parts.append(f'MODULES["{module}"] = function(script)\n{source}\nend\n')
    parts.append(open(os.path.join(HERE, "shared.spec.luau")).read())
    return "\n".join(parts)


def main() -> int:
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as f:
        f.write(bundle())
    result = subprocess.run(["luau", f.name], capture_output=True, text=True)
    os.unlink(f.name)
    sys.stdout.write(result.stdout + result.stderr)
    if result.returncode != 0 or "FAIL" in result.stdout or " 0 failed" not in result.stdout:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
