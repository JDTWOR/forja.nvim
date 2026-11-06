#!/usr/bin/env python3
"""Verify every Go exercise starter and reference solution offline."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
CURRICULUM = ROOT / "foundations.json"
ENV = {
    **os.environ,
    "GOPROXY": "off",
    "GOSUMDB": "off",
    "GOTOOLCHAIN": "local",
}


def run(workspace: Path, *args: str, timeout: float) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            ["go", *args],
            cwd=workspace,
            env=ENV,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ""
        if isinstance(output, bytes):
            output = output.decode("utf-8", errors="replace")
        raise SystemExit(f"go {' '.join(args)} timed out after {timeout}s\n{output}") from error


def require_failure(result: subprocess.CompletedProcess[str], label: str) -> None:
    if result.returncode == 0:
        raise SystemExit(f"{label} unexpectedly passed\n{result.stdout}")
    if "build failed" in result.stdout.lower() or "no required module provides" in result.stdout.lower():
        raise SystemExit(f"{label} failed to compile instead of failing an assertion\n{result.stdout}")


def require_success(result: subprocess.CompletedProcess[str], label: str) -> None:
    if result.returncode != 0:
        raise SystemExit(f"{label} failed\n{result.stdout}")


def verify_project(lesson_id: str, expected_id: str, project: Path, manifest_path: Path) -> None:
    manifest: dict[str, Any] = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("id") != expected_id:
        raise SystemExit(f"{manifest_path}: id={manifest.get('id')!r}, expected {expected_id!r}")
    required = {
        "schema_version": 1,
        "runner": "go-test",
        "package": "exercise",
        "source_file": "solution.go",
        "public_test_file": "solution_test.go",
        "assessment_file": "assessment_test.go",
        "solution_file": "solution.go",
        "timeout_ms": 30000,
    }
    for key, expected in required.items():
        if manifest.get(key) != expected:
            raise SystemExit(f"{manifest_path}: {key}={manifest.get(key)!r}, expected {expected!r}")

    starter = project / "starter"
    timeout = manifest["timeout_ms"] / 1000 + 15
    with tempfile.TemporaryDirectory(prefix="forja-go-starter-") as temporary:
        workspace = Path(temporary) / "workspace"
        shutil.copytree(starter, workspace)
        require_failure(run(workspace, "test", "-count=1", "./...", timeout=timeout), f"public starter {lesson_id}")
        assessment = workspace / "forja_assessment_test.go"
        assessment.write_text((project / manifest["assessment_file"]).read_text(encoding="utf-8"), encoding="utf-8")
        require_failure(
            run(workspace, "test", "-run", "^TestForjaAssessment", "-count=1", "./...", timeout=timeout),
            f"hidden starter {lesson_id}",
        )

    with tempfile.TemporaryDirectory(prefix="forja-go-solution-") as temporary:
        workspace = Path(temporary) / "workspace"
        shutil.copytree(starter, workspace)
        shutil.copyfile(project / manifest["solution_file"], workspace / manifest["source_file"])
        require_success(run(workspace, "test", "-count=1", "./...", timeout=timeout), f"public solution {lesson_id}")
        assessment = workspace / "forja_assessment_test.go"
        assessment.write_text((project / manifest["assessment_file"]).read_text(encoding="utf-8"), encoding="utf-8")
        require_success(
            run(workspace, "test", "-run", "^TestForjaAssessment", "-count=1", "./...", timeout=timeout),
            f"hidden solution {lesson_id}",
        )
    print(f"PASS {lesson_id}: public + hidden starters rejected; reference solution passes both suites")


def main() -> int:
    course = json.loads(CURRICULUM.read_text(encoding="utf-8"))
    if course.get("schema_version") != 1:
        raise SystemExit("unsupported Go curriculum schema_version")
    for lesson in course["lessons"]:
        exercise = lesson["exercise"]
        project = ROOT / exercise["project_dir"]
        verify_project(lesson["id"], lesson["id"], project, project / "exercise.json")
        transfer_dir = exercise.get("variation_dir")
        if not transfer_dir:
            raise SystemExit(f"{lesson['id']} has no transfer variation_dir")
        if len(lesson.get("variation_hints", [])) != 6:
            raise SystemExit(f"{lesson['id']} must contain exactly six variation_hints")
        transfer = project / transfer_dir
        verify_project(f"{lesson['id']} transfer", lesson["id"], transfer, transfer / "exercise.json")
    print(f"Verified {len(course['lessons'])} Go lessons and {len(course['lessons'])} transfer projects.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
