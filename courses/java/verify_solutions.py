#!/usr/bin/env python3
"""Compile Java starters and verify reference solutions with both test suites."""
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent / "exercises"


def run(args, cwd, expected=0):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if (expected == 0 and result.returncode != 0) or (expected != 0 and result.returncode == 0):
        details = result.stdout + result.stderr
        raise RuntimeError(f"command had exit {result.returncode}, expected {expected}: {' '.join(args)}\n{details}")
    return result


def main():
    exercises = sorted(path for path in ROOT.iterdir() if path.is_dir())
    if len(exercises) != 5:
        raise RuntimeError(f"expected five Java exercises, found {len(exercises)}")
    for exercise in exercises:
        with tempfile.TemporaryDirectory(prefix="forja-java-") as temporary:
            workspace = Path(temporary)
            starter = exercise / "starter"
            shutil.copytree(starter, workspace, dirs_exist_ok=True)
            classes = workspace / "classes"
            classes.mkdir()
            run(["javac", "-Xlint:all", "-d", str(classes), "Solution.java", "PublicTests.java"], workspace)
            run(["java", "-ea", "-cp", str(classes), "PublicTests"], workspace, expected=1)

            shutil.copyfile(exercise / "ForjaAssessment.java", workspace / "ForjaAssessment.java")
            run(["javac", "-Xlint:all", "-d", str(classes), "Solution.java", "ForjaAssessment.java"], workspace)
            run(["java", "-ea", "-cp", str(classes), "ForjaAssessment"], workspace, expected=1)

            shutil.copyfile(exercise / "Solution.java", workspace / "Solution.java")
            run(["javac", "-Xlint:all", "-d", str(classes), "Solution.java", "PublicTests.java", "ForjaAssessment.java"], workspace)
            run(["java", "-ea", "-cp", str(classes), "PublicTests"], workspace)
            run(["java", "-ea", "-cp", str(classes), "ForjaAssessment"], workspace)
            print(f"Verified Java exercise: {exercise.name}")
    print(f"Verified {len(exercises)} Java starters and reference solutions.")


if __name__ == "__main__":
    main()
