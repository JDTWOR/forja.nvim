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


def main() -> int:
    course = json.loads(CURRICULUM.read_text(encoding="utf-8"))
    for lesson in course["lessons"]:
        exercise = lesson["exercise"]
        project = ROOT / exercise["project_dir"]
        starter = project / exercise["starter_dir"]
        with tempfile.TemporaryDirectory(prefix="forja-python-starter-") as temporary:
            workspace = Path(temporary) / "workspace"
            shutil.copytree(starter, workspace)
            public = run(workspace, "test_public.py")
            if public.returncode == 0:
                raise SystemExit(f"starter unexpectedly passed public tests: {lesson['id']}\n{public.stdout}")
            hidden = workspace / "tests" / "test_forja_assessment.py"
            hidden.write_text((project / exercise["assessment_file"]).read_text(encoding="utf-8"), encoding="utf-8")
            assessment = run(workspace, "test_forja_assessment.py")
            if assessment.returncode == 0:
                raise SystemExit(f"starter unexpectedly passed assessment: {lesson['id']}\n{assessment.stdout}")

        with tempfile.TemporaryDirectory(prefix="forja-python-solution-") as temporary:
            workspace = Path(temporary) / "workspace"
            shutil.copytree(starter, workspace)
            shutil.copyfile(project / exercise["solution_file"], workspace / "solution.py")
            public = run(workspace, "test_public.py")
            if public.returncode != 0:
                raise SystemExit(f"reference solution failed public tests: {lesson['id']}\n{public.stdout}")
            hidden = workspace / "tests" / "test_forja_assessment.py"
            hidden.write_text((project / exercise["assessment_file"]).read_text(encoding="utf-8"), encoding="utf-8")
            assessment = run(workspace, "test_forja_assessment.py")
            if assessment.returncode != 0:
                raise SystemExit(f"reference solution failed assessment: {lesson['id']}\n{assessment.stdout}")
        print(f"Verified Python lesson {lesson['id']}: starter rejected, reference solution passes public and hidden tests.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
