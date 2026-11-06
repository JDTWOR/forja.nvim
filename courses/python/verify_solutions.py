#!/usr/bin/env python3
"""Verify that Python starters are incomplete and reference solutions pass both test layers."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CURRICULUM = ROOT / "foundations.json"
ENV = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}


def run(workspace: Path, pattern: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", pattern, "-v"],
        cwd=workspace,
        env={**ENV, "PYTHONPATH": str(workspace)},
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def verify_project(
    lesson_id: str,
    label: str,
    project: Path,
    starter: Path,
    assessment_file: str,
    solution_file: str,
    public_test_file: str,
) -> None:
    public_pattern = Path(public_test_file).name
    python_files = [
        starter / "solution.py",
        starter / public_test_file,
        project / assessment_file,
        project / solution_file,
    ]
    for source in python_files:
        try:
            compile(source.read_text(encoding="utf-8"), str(source), "exec")
        except (OSError, SyntaxError) as error:
            raise SystemExit(f"invalid Python source in {label} exercise {lesson_id}: {source}: {error}") from error

    with tempfile.TemporaryDirectory(prefix="forja-python-starter-") as temporary:
        workspace = Path(temporary) / "workspace"
        shutil.copytree(starter, workspace)
        public = run(workspace, public_pattern)
        if public.returncode == 0:
            raise SystemExit(f"{label} starter unexpectedly passed public tests: {lesson_id}\n{public.stdout}")
        hidden = workspace / "tests" / "test_forja_assessment.py"
        hidden.write_text((project / assessment_file).read_text(encoding="utf-8"), encoding="utf-8")
        assessment = run(workspace, "test_forja_assessment.py")
        if assessment.returncode == 0:
            raise SystemExit(f"{label} starter unexpectedly passed assessment: {lesson_id}\n{assessment.stdout}")

    with tempfile.TemporaryDirectory(prefix="forja-python-solution-") as temporary:
        workspace = Path(temporary) / "workspace"
        shutil.copytree(starter, workspace)
        shutil.copyfile(project / solution_file, workspace / "solution.py")
        public = run(workspace, public_pattern)
        if public.returncode != 0:
            raise SystemExit(f"{label} reference solution failed public tests: {lesson_id}\n{public.stdout}")
        hidden = workspace / "tests" / "test_forja_assessment.py"
        hidden.write_text((project / assessment_file).read_text(encoding="utf-8"), encoding="utf-8")
        assessment = run(workspace, "test_forja_assessment.py")
        if assessment.returncode != 0:
            raise SystemExit(f"{label} reference solution failed assessment: {lesson_id}\n{assessment.stdout}")


def main() -> int:
    course = json.loads(CURRICULUM.read_text(encoding="utf-8"))
    for lesson in course["lessons"]:
        exercise = lesson["exercise"]
        project = ROOT / exercise["project_dir"]
        starter = project / exercise["starter_dir"]
        base_manifest = json.loads((project / "exercise.json").read_text(encoding="utf-8"))
        verify_project(
            lesson["id"], "base", project, starter,
            exercise["assessment_file"], exercise["solution_file"], base_manifest["public_test_file"],
        )
        print(f"Verified Python lesson {lesson['id']} base exercise: starter rejected; reference passes public and hidden tests.")

        variation_dir = exercise.get("variation_dir")
        if not variation_dir:
            raise SystemExit(f"missing transfer exercise: {lesson['id']}")
        transfer = project / variation_dir
        transfer_manifest = json.loads((transfer / "exercise.json").read_text(encoding="utf-8"))
        if transfer_manifest.get("id") != lesson["id"] or transfer_manifest.get("runner") != base_manifest.get("runner"):
            raise SystemExit(f"transfer manifest does not match base runner and lesson id: {lesson['id']}")
        verify_project(
            lesson["id"], "transfer", transfer, transfer / "starter",
            transfer_manifest["assessment_file"], transfer_manifest["solution_file"],
            transfer_manifest["public_test_file"],
        )
        print(f"Verified Python lesson {lesson['id']} transfer exercise: starter rejected; reference passes public and hidden tests.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
