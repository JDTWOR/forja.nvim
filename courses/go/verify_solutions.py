#!/usr/bin/env python3
"""Verify Go starters and reference solutions using visible and hidden tests."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CURRICULUM = ROOT / "foundations.json"
ENV = {
    **os.environ,
    "GOPROXY": "off",
    "GOSUMDB": "off",
    "GOTOOLCHAIN": "local",
}


def run(workspace: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["go", *args],
        cwd=workspace,
        env=ENV,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def require_failure(result: subprocess.CompletedProcess[str], label: str) -> None:
    if result.returncode == 0:
        raise SystemExit(f"{label} unexpectedly passed\n{result.stdout}")


def require_success(result: subprocess.CompletedProcess[str], label: str) -> None:
    if result.returncode != 0:
        raise SystemExit(f"{label} failed\n{result.stdout}")


def main() -> int:
    course = json.loads(CURRICULUM.read_text(encoding="utf-8"))
    for lesson in course["lessons"]:
        exercise = lesson["exercise"]
        project = ROOT / exercise["project_dir"]
        starter = project / exercise["starter_dir"]

        with tempfile.TemporaryDirectory(prefix="forja-go-starter-") as temporary:
            workspace = Path(temporary) / "workspace"
            shutil.copytree(starter, workspace)
            require_failure(run(workspace, "test", "./..."), f"public starter {lesson['id']}")
            assessment = workspace / "forja_assessment_test.go"
            assessment.write_text(
                (project / exercise["assessment_file"]).read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            require_failure(
                run(workspace, "test", "-run", "^TestForjaAssessment", "./..."),
                f"hidden starter {lesson['id']}",
            )

        with tempfile.TemporaryDirectory(prefix="forja-go-solution-") as temporary:
            workspace = Path(temporary) / "workspace"
            shutil.copytree(starter, workspace)
            shutil.copyfile(project / exercise["solution_file"], workspace / "solution.go")
            require_success(run(workspace, "test", "./..."), f"public solution {lesson['id']}")
            assessment = workspace / "forja_assessment_test.go"
            assessment.write_text(
                (project / exercise["assessment_file"]).read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            require_success(
                run(workspace, "test", "-run", "^TestForjaAssessment", "./..."),
                f"hidden solution {lesson['id']}",
            )
        print(f"Verified Go lesson {lesson['id']}: starter rejected, reference solution passes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
