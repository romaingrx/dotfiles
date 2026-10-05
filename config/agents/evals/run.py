#!/usr/bin/env python3
"""Run the skill evals in scenarios.json as fresh headless Claude Code sessions.

Each (scenario, model) pair runs in a throwaway copy of fixture/ with this
checkout's skills linked in as project skills, then is graded from the tool
calls the session made. Transcripts land in --out for reading by hand.

    python3 config/agents/evals/run.py --models haiku,sonnet,opus
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
SKILLS = HERE.parent / "skills"
ALLOWED = [
    "Read", "Grep", "Glob", "Edit", "Write", "Skill", "TodoWrite", "Agent",
    "Bash(python3:*)", "Bash(python:*)", "Bash(pytest:*)", "Bash(ls:*)",
    "Bash(cat:*)", "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)",
]
VERIFY = {
    "pages_disjoint": (
        "from shop.catalog import PRODUCTS, paginate\n"
        "pages = [paginate(PRODUCTS, p, 3) for p in range(1, 5)]\n"
        "assert sum(pages, []) == PRODUCTS, pages\n"
    ),
    "renamed": (
        "import re; s = open('shop/cli.py').read()\n"
        "assert 'per_page' in s and not re.search(r'\\bn\\b', s), s\n"
    ),
}


def setup(workdir):
    shutil.copytree(HERE / "fixture", workdir)
    links = workdir / ".claude" / "skills"
    links.mkdir(parents=True)
    for skill in SKILLS.iterdir():
        if (skill / "SKILL.md").exists():
            (links / skill.name).symlink_to(skill)
    git = ["git", "-C", str(workdir), "-c", "user.name=eval", "-c", "user.email=eval@localhost"]
    subprocess.run([*git, "init", "-q"], check=True)
    subprocess.run([*git, "add", "-A"], check=True)
    subprocess.run([*git, "commit", "-qm", "init"], check=True)


def tool_calls(transcript):
    calls = []
    for line in transcript.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") != "assistant":
            continue
        for block in event["message"].get("content", []):
            if block.get("type") == "tool_use":
                calls.append((block["name"], block.get("input", {})))
    return calls


def result_event(transcript):
    for line in reversed(transcript.splitlines()):
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "result":
            return event
    return {"is_error": True, "result": "no result event (timeout or crash)"}


def grade(checks, calls, workdir):
    skills = [i.get("skill") or i.get("command") for n, i in calls if n == "Skill"]
    reads = [i.get("file_path", "") for n, i in calls if n == "Read"]
    bash = [(k, i.get("command", "")) for k, (n, i) in enumerate(calls) if n == "Bash"]
    edits = [(k, i.get("file_path", "")) for k, (n, i) in enumerate(calls) if n in ("Edit", "Write", "MultiEdit")]
    todos = json.dumps([i for n, i in calls if "Todo" in n or n.startswith("Task")])
    results = {}
    if "skill" in checks:
        results["skill " + checks["skill"]] = checks["skill"] in skills
    if "not_skill" in checks:
        results["no skill " + checks["not_skill"]] = checks["not_skill"] not in skills
    if "reads" in checks:
        results["reads " + checks["reads"]] = any(r.endswith(checks["reads"]) for r in reads)
    if "todo_mentions" in checks:
        results["todo mentions " + checks["todo_mentions"]] = checks["todo_mentions"] in todos
    if "run_before_edit" in checks:
        target = checks["run_before_edit"]
        first_edit = next((k for k, p in edits if p.endswith(target)), None)
        first_run = next((k for k, c in bash if "python" in c or "pytest" in c), None)
        results["runs before editing " + target] = (
            first_run is not None and (first_edit is None or first_run < first_edit)
        )
    if "edits_under" in checks:
        results["edits " + checks["edits_under"]] = any(checks["edits_under"] in p for _, p in edits)
    if "bash_mentions" in checks:
        results["measures repeatedly"] = any(re.search(checks["bash_mentions"], c) for _, c in bash)
    for word in checks.get("no_git", []):
        results["no git " + word] = not any(f"git {word}" in c for _, c in bash)
    if "verify" in checks:
        ok = subprocess.run(
            [sys.executable, "-c", VERIFY[checks["verify"]]], cwd=workdir, capture_output=True
        ).returncode == 0
        results["outcome " + checks["verify"]] = ok
    return results


def run(scenario, model, out):
    name = f"{scenario['id']}.{model}"
    workdir = Path(tempfile.mkdtemp(prefix="skill-eval-")) / "repo"
    setup(workdir)
    cmd = [
        "claude", "-p", scenario["query"], "--model", model,
        "--output-format", "stream-json", "--verbose",
        "--permission-mode", "acceptEdits", "--strict-mcp-config",
        "--no-session-persistence", "--allowedTools", *ALLOWED,
    ]
    try:
        proc = subprocess.run(cmd, cwd=workdir, capture_output=True, text=True, timeout=900)
        transcript = proc.stdout
    except subprocess.TimeoutExpired as exc:
        transcript = exc.stdout or ""
    (out / f"{name}.jsonl").write_text(transcript)
    result = result_event(transcript)
    (out / f"{name}.reply.md").write_text(result.get("result", ""))
    if result.get("is_error") and not tool_calls(transcript):
        return name, result.get("result") or "session error"
    return name, grade(scenario["checks"], tool_calls(transcript), workdir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--models", default="haiku,sonnet,opus")
    parser.add_argument("--only", help="run one scenario id")
    parser.add_argument("--out", type=Path, default=Path(tempfile.mkdtemp(prefix="skill-evals-")))
    args = parser.parse_args()
    scenarios = json.loads((HERE / "scenarios.json").read_text())
    jobs = [
        (s, m) for s in scenarios for m in args.models.split(",")
        if not args.only or s["id"] == args.only
    ]
    args.out.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
        results = list(pool.map(lambda job: run(*job, args.out), jobs))
    failed = 0
    for name, checks in results:
        if isinstance(checks, str):
            failed += 1
            print(f"ERROR {name}: {checks}")
            continue
        passed = sum(checks.values())
        print(f"{'PASS' if passed == len(checks) else 'FAIL'} {name} ({passed}/{len(checks)})")
        for check, ok in checks.items():
            if not ok:
                failed += 1
                print(f"     x {check}")
    print(f"transcripts: {args.out}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
