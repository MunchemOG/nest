#!/usr/bin/env python3
"""Control panel for scripts/autorun.sh, served only to this Mac at http://127.0.0.1:8765.

Shows the queue and what is running; adds, edits, skips and deletes tasks; sets each
task's model tier and the hours the runner works; starts and stops the runner.
Its settings live in .autorun/ (not tracked by git), which the runner re-reads before every task.
"""
import json
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PANEL = ROOT / ".autorun"
LOGS = ROOT / "logs" / "autorun"
TIERS_DEFAULT = ROOT / "scripts" / "autorun-tiers.txt"
TIERS = PANEL / "tiers.txt"
EXTRA = PANEL / "tasks.json"
SKIP = PANEL / "skip.txt"
SCHEDULE = PANEL / "schedule.txt"
CURRENT = PANEL / "current"
STOP = ROOT / ".autorun-stop"
PAGE = Path(__file__).resolve().parent / "autorun-panel.html"
PORT = 8765
ROW = re.compile(r"^\|\s*([A-Z0-9]+-[0-9]+)\s*\|(.*?)\|(.*?)\|(.*?)\|\s*$")


def run(*args):
    return subprocess.run(list(args), cwd=ROOT, capture_output=True, text=True)


def read_lines(path):
    return path.read_text().splitlines() if path.exists() else []


def read_tiers():
    tiers = {}
    for path in (TIERS_DEFAULT, TIERS):
        for line in read_lines(path):
            parts = line.split()
            if len(parts) == 2 and not line.startswith("#") and parts[0] != "fable-until":
                tiers[parts[0]] = parts[1]
    return tiers


def fable_until():
    for line in read_lines(TIERS_DEFAULT):
        parts = line.split()
        if len(parts) == 2 and parts[0] == "fable-until":
            return parts[1]
    return ""


def read_extra():
    try:
        return json.loads(EXTRA.read_text())
    except (OSError, ValueError):
        return []


def write_extra(tasks):
    PANEL.mkdir(exist_ok=True)
    EXTRA.write_text(json.dumps(tasks, indent=2))


def merged_ids():
    first_parent = set(run("git", "rev-list", "--first-parent", "main").stdout.split())
    merged = set()
    refs = run("git", "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads/task/").stdout
    for line in refs.splitlines():
        name, sha = line.split()
        if sha not in first_parent and run("git", "merge-base", "--is-ancestor", sha, "main").returncode == 0:
            merged.add(name[len("task/"):])
    return merged


def runner_running():
    return run("pgrep", "-f", "scripts/autorun.sh").returncode == 0


def costs():
    per_task, total = {}, 0.0
    for line in read_lines(LOGS / "costs.tsv")[1:]:
        parts = line.split("\t")
        if len(parts) == 4:
            try:
                usd = float(parts[3])
            except ValueError:
                continue
            per_task[parts[1]] = per_task.get(parts[1], 0.0) + usd
            total += usd
    return per_task, total


def state():
    tiers, skipped, merged = read_tiers(), set(read_lines(SKIP)), merged_ids()
    per_task, total = costs()
    current = CURRENT.read_text().split() if CURRENT.exists() else []
    tasks = [dict(t, source="added") for t in read_extra()]
    for line in read_lines(ROOT / "docs" / "queue.md"):
        m = ROW.match(line)
        if m and m.group(1) != "id":
            tasks.append(dict(id=m.group(1), goal=m.group(2).strip(), done_means=m.group(3).strip(), needs=m.group(4).strip(), source="queue"))
    for t in tasks:
        t["tier"] = tiers.get(t["id"], "light")
        t["skipped"] = t["id"] in skipped
        t["cost"] = round(per_task.get(t["id"], 0.0), 2)
        if t["id"] in merged:
            t["state"] = "merged"
        elif current and current[0] == t["id"]:
            t["state"] = "running"
        elif t["skipped"]:
            t["state"] = "skipped"
        else:
            t["state"] = "waiting"
    schedule = SCHEDULE.read_text().split() if SCHEDULE.exists() else ["always"]
    return dict(
        running=runner_running(),
        stopping=STOP.exists(),
        current=" ".join(current),
        schedule=schedule,
        fable_until=fable_until(),
        total_cost=round(total, 2),
        log=read_lines(LOGS / "autorun.log")[-40:],
        tasks=tasks,
    )


def set_tier(task_id, tier):
    lines = [l for l in read_lines(TIERS) if l.split()[:1] != [task_id]]
    lines.append(f"{task_id} {tier}")
    PANEL.mkdir(exist_ok=True)
    TIERS.write_text("\n".join(lines) + "\n")


def set_skip(task_id, skip):
    lines = [l for l in read_lines(SKIP) if l != task_id]
    if skip:
        lines.append(task_id)
    PANEL.mkdir(exist_ok=True)
    SKIP.write_text("\n".join(lines) + ("\n" if lines else ""))


def save_task(body):
    tasks = read_extra()
    goal, done = body.get("goal", "").strip(), body.get("done_means", "").strip()
    if not goal or not done:
        return "A task needs a goal and a done-means test."
    if body.get("id"):
        for t in tasks:
            if t["id"] == body["id"]:
                t["goal"], t["done_means"] = goal, done
    else:
        used = [int(t["id"].split("-")[1]) for t in tasks]
        tasks.append(dict(id=f"X-{max(used, default=0) + 1:02d}", goal=goal, done_means=done))
    write_extra(tasks)
    return ""


def move_task(task_id, step):
    tasks = read_extra()
    i = next((n for n, t in enumerate(tasks) if t["id"] == task_id), None)
    if i is not None and 0 <= i + step < len(tasks):
        tasks[i], tasks[i + step] = tasks[i + step], tasks[i]
        write_extra(tasks)


def delete_task(task_id):
    write_extra([t for t in read_extra() if t["id"] != task_id])


def set_schedule(mode, on, off):
    PANEL.mkdir(exist_ok=True)
    if mode == "window" and re.fullmatch(r"\d\d:\d\d", on or "") and re.fullmatch(r"\d\d:\d\d", off or ""):
        SCHEDULE.write_text(f"{on} {off}\n")
    else:
        SCHEDULE.write_text("always\n")


def start_runner():
    if runner_running():
        return
    STOP.unlink(missing_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    with open(LOGS / "nohup.out", "a") as out:
        subprocess.Popen(["nohup", "scripts/autorun.sh"], cwd=ROOT, stdout=out, stderr=out, start_new_session=True)


def stop_now():
    run("pkill", "-f", "scripts/autorun.sh")
    run("pkill", "-f", "claude -p --model")
    run("pkill", "-f", "xcodebuild test -scheme NestApp")
    CURRENT.unlink(missing_ok=True)


class Panel(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send(self, code, body, kind="application/json"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/":
            self.send(200, PAGE.read_text(), "text/html; charset=utf-8")
        elif self.path == "/api/state":
            self.send(200, json.dumps(state()))
        else:
            self.send(404, "{}")

    def do_POST(self):
        # Only the panel page itself may change things.
        if self.headers.get("Origin") not in (None, f"http://127.0.0.1:{PORT}", f"http://localhost:{PORT}"):
            self.send(403, "{}")
            return
        length = int(self.headers.get("Content-Length") or 0)
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
        except ValueError:
            body = {}
        error = ""
        action = self.path.removeprefix("/api/")
        if action == "tier" and body.get("tier") in ("light", "heavy", "manual"):
            set_tier(body["id"], body["tier"])
        elif action == "skip":
            set_skip(body["id"], bool(body.get("skip")))
        elif action == "save":
            error = save_task(body)
        elif action == "move":
            move_task(body["id"], int(body.get("step", 0)))
        elif action == "delete":
            delete_task(body["id"])
        elif action == "schedule":
            set_schedule(body.get("mode"), body.get("on"), body.get("off"))
        elif action == "start":
            start_runner()
        elif action == "stop":
            if runner_running():
                STOP.touch()
        elif action == "stopnow":
            stop_now()
        else:
            self.send(404, "{}")
            return
        self.send(200, json.dumps(dict(error=error)))


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Panel).serve_forever()
