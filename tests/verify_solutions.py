#!/usr/bin/env python3
"""Compile every reference solution with visible and isolated assessment tests."""
from pathlib import Path
import shutil
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
projects = []
for exercise in sorted((root / "courses/rust/exercises").iterdir()):
    projects.append((exercise.name, exercise / "starter", exercise / "solution.rs", exercise / "assessment.rs"))
    transfer = exercise / "transfer"
    if transfer.exists():
        projects.append((f"{exercise.name} transfer", transfer / "starter", transfer / "solution.rs", transfer / "assessment.rs"))

for name, starter, solution, assessment in projects:
    with tempfile.TemporaryDirectory(prefix="forja-solution-") as temporary:
        target = Path(temporary)
        shutil.copytree(starter, target, dirs_exist_ok=True)
        print(f"Checking clean starter {name}", flush=True)
        check = subprocess.run(["cargo", "check", "--offline"], cwd=target, check=True, capture_output=True, text=True)
        diagnostics = check.stdout + check.stderr
        if "warning:" in diagnostics:
            raise RuntimeError(f"Starter {name} emits compiler warnings:\n{diagnostics}")
        shutil.copyfile(solution, target / "src/lib.rs")
        shutil.copyfile(assessment, target / "tests/forja_assessment.rs")
        print(f"Verifying {name}", flush=True)
        subprocess.run(["cargo", "test", "--offline"], cwd=target, check=True)
print(f"Checked {len(projects)} clean starters and verified their reference solutions against visible and assessment tests.")
