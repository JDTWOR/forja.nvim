#!/usr/bin/env python3
"""Compile every Java exercise starter and verify its reference solutions."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


COURSE_ROOT = Path(__file__).resolve().parent
EXERCISES_ROOT = COURSE_ROOT / "exercises"
EXPECTED_LESSONS = {
    "variables-primitives",
    "control-flow",
    "methods",
    "arrays-collections",
    "classes-encapsulation",
}


def run(args, cwd, expected=0):
    try:
        result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, timeout=30)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"command timed out: {' '.join(args)}") from error
    succeeded = result.returncode == 0
    if succeeded != (expected == 0):
        details = result.stdout + result.stderr
        raise RuntimeError(
            f"command had exit {result.returncode}, expected "
            f"{'zero' if expected == 0 else 'nonzero'}: {' '.join(args)}\n{details}"
        )
    return result


def validate_manifest(project):
    manifest_path = project / "exercise.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    required = {
        "schema_version": 1,
        "runner": "java-main",
        "source_file": "Solution.java",
        "public_test_file": "PublicTests.java",
        "assessment_file": "ForjaAssessment.java",
        "solution_file": "Solution.java",
        "timeout_ms": 30000,
    }
    for key, expected in required.items():
        if manifest.get(key) != expected:
            raise RuntimeError(f"{manifest_path}: expected {key}={expected!r}, got {manifest.get(key)!r}")
    package = manifest.get("package")
    if not isinstance(package, str) or not package or package.lower() != package:
        raise RuntimeError(f"{manifest_path}: package must be a non-empty lowercase slug")
    return manifest


def verify_project(project, label):
    manifest = validate_manifest(project)
    starter = project / "starter"
    required_files = [
        starter / "Solution.java",
        starter / "PublicTests.java",
        project / "ForjaAssessment.java",
        project / "Solution.java",
    ]
    missing = [str(path) for path in required_files if not path.is_file()]
    if missing:
        raise RuntimeError(f"{label}: missing required files: {', '.join(missing)}")

    with tempfile.TemporaryDirectory(prefix="forja-java-") as temporary:
        workspace = Path(temporary)
        shutil.copytree(starter, workspace, dirs_exist_ok=True)
        classes = workspace / "classes"
        classes.mkdir()
        run(["javac", "-Xlint:all", "-d", str(classes), "Solution.java", "PublicTests.java"], workspace)
        shutil.copyfile(project / "ForjaAssessment.java", workspace / "ForjaAssessment.java")
        run(["javac", "-Xlint:all", "-d", str(classes), "Solution.java", "ForjaAssessment.java"], workspace)
        run(["java", "-ea", "-cp", str(classes), "PublicTests"], workspace, expected=1)
        run(["java", "-ea", "-cp", str(classes), "ForjaAssessment"], workspace, expected=1)

        shutil.copyfile(project / manifest["solution_file"], workspace / "Solution.java")
        run(
            ["javac", "-Xlint:all", "-d", str(classes), "Solution.java", "PublicTests.java", "ForjaAssessment.java"],
            workspace,
        )
        run(["java", "-ea", "-cp", str(classes), "PublicTests"], workspace)
        run(["java", "-ea", "-cp", str(classes), "ForjaAssessment"], workspace)
    print(f"Verified {label}: starter fails both suites; reference passes both suites.")


def main():
    exercises = sorted(path for path in EXERCISES_ROOT.iterdir() if path.is_dir())
    lesson_ids = {path.name for path in exercises}
    if lesson_ids != EXPECTED_LESSONS:
        raise RuntimeError(f"expected lesson dirs {sorted(EXPECTED_LESSONS)}, found {sorted(lesson_ids)}")

    projects = []
    for exercise in exercises:
        projects.append((exercise, f"base/{exercise.name}"))
        transfer = exercise / "transfer"
        if not transfer.is_dir():
            raise RuntimeError(f"{exercise.name}: missing transfer project")
        projects.append((transfer, f"transfer/{exercise.name}"))

    for project, label in projects:
        verify_project(project, label)
    print(f"Verified {len(exercises)} Java lessons and {len(projects)} exercise projects.")


if __name__ == "__main__":
    main()
