#!/usr/bin/env python3
"""Runs the BehaviorSpace regression experiments headless and checks their results.

Usage: python3 tests/check_regression.py [NETLOGO_HOME]
NETLOGO_HOME defaults to $NETLOGO_HOME or "/Applications/NetLogo 7.0.4".

Checks, for every run of "regression-no-delay" (random tasks, delay = advance = 0) in the
desktop and the web models:
  * all tasks end up done,
  * no task is ever started/finished while one of its predecessors is not done,
  * the real duration is close to the planned one (PMB-Duration). It is not always exactly
    equal: an employee picks one task per tick, and greedy scheduling can react to that.
and, for "regression-plan-csv" (MS Project plan, desktop only), the first two checks.
"""
import collections, csv, os, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("NETLOGO_HOME", "/Applications/NetLogo 7.0.4")
DONE = 'count tasks with [status = "done"]'
VIOL = 'count tasks with [status != "to-do" and any? predecessor-tasks with [status != "done"]]'


def run(model, experiment):
    out = os.path.join(tempfile.mkdtemp(), "table.csv")
    cmd = [os.path.join(HOME, "NetLogo_Console"), "--headless", "--model", os.path.join(ROOT, model),
           "--experiment", experiment, "--table", out]
    subprocess.run(cmd, cwd=HOME, check=True, capture_output=True)
    rows = list(csv.reader(open(out)))
    start = next(i for i, r in enumerate(rows) if r and r[0] == "[run number]")
    header, data = rows[start], rows[start + 1:]
    runs = collections.defaultdict(list)
    for r in data:
        runs[r[0]].append(dict(zip(header, r)))
    return runs


def check(model, experiment, planned_close):
    failures = []
    runs = run(model, experiment)
    for run_id, steps in runs.items():
        last = steps[-1]
        if last[DONE] != last["count tasks"]:
            failures.append(f"{model} {experiment} run {run_id}: {last[DONE]}/{last['count tasks']} tasks done")
        if any(int(s[VIOL]) for s in steps):
            failures.append(f"{model} {experiment} run {run_id}: precedence violated")
        if planned_close:
            planned, real = float(last["PMB-Duration"]), float(last["ticks"])
            if abs(real - planned) > max(5, 0.03 * planned):
                failures.append(f"{model} {experiment} run {run_id}: ticks {real:g} vs planned {planned:g}")
    print(f"{model} {experiment}: {len(runs)} runs, {len(failures)} failures")
    return failures


failures = []
failures += check("NetlogoEarnedValueManagementV1.1.nlogox", "regression-no-delay", True)
failures += check("NetlogoEarnedValueManagementV1.1.nlogox", "regression-plan-csv", False)
failures += check("NetlogoEarnedValueManagementWebV1.1.nlogox", "regression-no-delay", True)
for f in failures:
    print("FAIL", f)
sys.exit(1 if failures else 0)
