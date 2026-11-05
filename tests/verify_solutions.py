#!/usr/bin/env python3
"""Compile every reference solution with visible and isolated assessment tests."""
from pathlib import Path
import shutil
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
exercises = sorted((root / "courses/rust/exercises").iterdir())
for exercise in exercises:
    with tempfile.TemporaryDirectory(prefix="forja-solution-") as temporary:
        target = Path(temporary)
        shutil.copytree(exercise / "starter", target, dirs_exist_ok=True)
        shutil.copyfile(exercise / "solution.rs", target / "src/lib.rs")
        shutil.copyfile(exercise / "assessment.rs", target / "tests/forja_assessment.rs")
        print(f"Verifying {exercise.name}", flush=True)
        subprocess.run(["cargo", "test", "--offline"], cwd=target, check=True)
print(f"Verified {len(exercises)} reference solutions against visible and assessment tests.")
