#!/usr/bin/env python3
"""Compare numeric XCTest metrics exported by run-performance.sh.

Usage: compare-performance.py baseline.json candidate.json [allowed_percent]
Only metrics that become slower/larger by more than the threshold fail the command.
"""
import json
import sys

def values(value, path=""):
    if isinstance(value, dict):
        label = value.get("identifier") or value.get("name") or value.get("displayName") or path
        for key, child in value.items():
            if key in {"value", "average", "median", "max"} and isinstance(child, (int, float)):
                yield f"{label}.{key}", float(child)
            yield from values(child, f"{path}.{key}" if path else key)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from values(child, f"{path}[{index}]")

baseline = dict(values(json.load(open(sys.argv[1]))))
candidate = dict(values(json.load(open(sys.argv[2]))))
threshold = float(sys.argv[3]) if len(sys.argv) > 3 else 10.0
regressions = []
for name, old in baseline.items():
    new = candidate.get(name)
    if new is not None and old > 0 and new > old * (1 + threshold / 100):
        regressions.append(f"{name}: {old:.3f} -> {new:.3f} ({(new / old - 1) * 100:.1f}%)")
if regressions:
    print("Performance regressions:\n" + "\n".join(regressions))
    sys.exit(1)
print("No comparable metric exceeded the regression threshold.")
