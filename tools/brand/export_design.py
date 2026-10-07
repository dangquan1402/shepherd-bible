#!/usr/bin/env python3
"""Batch export design frames from screens/shepherd.pen to design/exports."""

import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PEN = os.path.join(ROOT, "design/screens/shepherd.pen")
EXP = os.path.join(ROOT, "design/exports")
TSV = os.path.join(EXP, "index.tsv")

with open(TSV) as f:
    rows = [line.strip().split("\t") for line in f if line.strip()]

batch_size = 10
total = len(rows)
print(f"Exporting {total} frames in batches of {batch_size}...")

for i in range(0, total, batch_size):
    chunk = rows[i : i + batch_size]
    ids = [r[0] for r in chunk]
    js = f"Export({json.dumps(ids)}, \"png\", {json.dumps(EXP)}, {{scale: 1}})"
    payload = f"execute({{ input: {json.dumps(js)} }})\nexit()\n"
    res = subprocess.run(
        ["pen", "interactive", "--in", PEN, "--out", PEN],
        input=payload,
        text=True,
        capture_output=True,
    )
    if res.returncode != 0:
        print(f"Error on batch {i // batch_size + 1}: {res.stderr}")
        sys.exit(1)
    for node_id, filename in chunk:
        raw_path = os.path.join(EXP, f"{node_id}.png")
        target_path = os.path.join(EXP, filename)
        if os.path.exists(raw_path):
            shutil.move(raw_path, target_path)
            print(f"  {node_id} -> {filename}")
        else:
            print(f"  WARNING: {raw_path} not found")

print("All exports completed successfully.")
