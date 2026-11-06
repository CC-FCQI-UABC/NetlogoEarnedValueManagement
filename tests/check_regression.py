#!/usr/bin/env python3
"""Runs the BehaviorSpace regression experiments headless and checks their results.

Usage: python3 tests/check_regression.py [NETLOGO_HOME]
NETLOGO_HOME defaults to $NETLOGO_HOME or "/Applications/NetLogo 7.0.4".

Also checks the plan reader: "regression-parsing" (lag, link type and date parsers, 17 expressions) and
"regression-plan-files" (the files in tests/plans: one tolerant file and six with a deliberate error, which
must fail with the expected line number and message and create no tasks). Experiments run with one thread,
because parallel runs hang while reading files.

Checks, for every run of "regression-no-delay" (random tasks, delay = advance = 0) in the
desktop and the web models:
  * all tasks end up done,
  * no task is ever started while its predecessors (including lags) are not satisfied,
  * the real duration is close to the planned one (PMB-Duration). It is not always exactly
    equal: an employee picks one task per tick, and greedy scheduling can react to that.
and the same for "regression-plan-csv" (MS Project plan, desktop only, with its lags and leads) and
"regression-link-types" (input/Plan-link-types.csv: one link each of type SS, FF, FS with a percentage lag,
SF and FS with a lag; the ideal run must reproduce the plan to within a tick).
"""
import collections, csv, os, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("NETLOGO_HOME", "/Applications/NetLogo 7.0.4")
DONE = 'count tasks with [status = "done"]'
VIOL = 'count tasks with [status != "to-do" and not ready?]'
FINV = 'count tasks with [finish-violation?]'


def run(model, experiment):
    out = os.path.join(tempfile.mkdtemp(), "table.csv")
    cmd = [os.path.join(HOME, "NetLogo_Console"), "--headless", "--model", os.path.join(ROOT, model),
           "--experiment", experiment, "--threads", "1", "--table", out]   # parallel runs hang on file reading
    subprocess.run(cmd, cwd=HOME, check=True, capture_output=True)
    rows = list(csv.reader(open(out)))
    start = next(i for i, r in enumerate(rows) if r and r[0] == "[run number]")
    header, data = rows[start], rows[start + 1:]
    runs = collections.defaultdict(list)
    for r in data:
        runs[r[0]].append(dict(zip(header, r)))
    return runs


def check(model, experiment, planned_close, abs_tol=5):
    failures = []
    runs = run(model, experiment)
    for run_id, steps in runs.items():
        last = steps[-1]
        if last[DONE] != last["count tasks"]:
            failures.append(f"{model} {experiment} run {run_id}: {last[DONE]}/{last['count tasks']} tasks done")
        if any(int(s[VIOL]) for s in steps):
            failures.append(f"{model} {experiment} run {run_id}: a task started before its start-gate links held")
        if any(int(s[FINV]) for s in steps):
            failures.append(f"{model} {experiment} run {run_id}: a task finished before its finish-gate links held")
        if planned_close:
            planned, real = float(last["PMB-Duration"]), float(last["ticks"])
            if abs(real - planned) > max(abs_tol, 0.03 * planned):
                failures.append(f"{model} {experiment} run {run_id}: ticks {real:g} vs planned {planned:g}")
    print(f"{model} {experiment}: {len(runs)} runs, {len(failures)} failures")
    return failures


PARSING = {
    'parse-predecessor "29"': '[29 0 FS false]',
    'parse-predecessor "29FS-11.25 days"': '[29 -90 FS false]',
    'parse-predecessor "2SS+8 hrs"': '[2 8 SS false]',
    'parse-predecessor "2FS+50%"': '[2 50 FS true]',
    'parse-predecessor "7FF-2 days"': '[7 -16 FF false]',
    'parse-predecessor "3SF+1 wk"': '[3 40 SF false]',
    'parse-predecessor "4FS+60 mins"': '[4 1 FS false]',
    'parse-predecessor "x1"': '[]',
    'predecessor-specs (list 0 0 0 0 0 0 0 0 0 0 0 0 "33,31")': '[[33 0 FS false] [31 0 FS false]]',
    '(parse-plan-tick "Tue 11/8/22 1:00 PM") - (parse-plan-tick "Mon 11/7/22 8:00 AM")': '12',
    '(parse-plan-tick "Mon 11/14/22 8:00 AM") - (parse-plan-tick "Fri 11/11/22 5:00 PM")': '0',
    '(parse-plan-tick "11/8/2022 13:00") - (parse-plan-tick "11/7/22 8:00 am")': '12',
    'parse-plan-date-time "Mon 11/7/22 8:00 AM"': '[2022 11 7 8 0]',
    'parse-plan-date-time "Mon 13/40/22 8:00 AM"': '[]',
    'parse-plan-date-time "tomorrow"': '[]',
    'parse-plan-date-time "12/1/2022 12:30 pm"': '[2022 12 1 12 30]',
    'parse-plan-date-time "12/1/2022 12:30 am"': '[2022 12 1 0 30]',
}

# plan file -> (start of the expected plan-error, expected number of tasks)
PLAN_FILES = {
    "tests/plans/ok-tolerant.csv": ("", 3),   # header, blank lines, 4-digit years, am/pm, 24-hour clock
    "tests/plans/bad-short-row.csv": ("line 1: expected at least 13 columns", 0),
    "tests/plans/bad-date.csv": ("line 1: cannot read the start date", 0),
    "tests/plans/bad-hours.csv": ("line 1: work hours in column 11 must be a number", 0),
    "tests/plans/bad-unknown-predecessor.csv": ("line 2: predecessor 9 is not in the plan", 0),
    "tests/plans/bad-predecessor-syntax.csv": ("line 2: cannot read the predecessors", 0),
    "tests/plans/bad-duplicate-id.csv": ("line 2: duplicate ID 1", 0),
}


def check_parsing():
    failures = []
    steps = next(iter(run("NetlogoEarnedValueManagementV1.2.nlogox", "regression-parsing").values()))
    last = steps[-1]
    for expression, expected in PARSING.items():
        if last[expression] != expected:
            failures.append(f"parsing {expression}: got {last[expression]}, expected {expected}")
    print(f"regression-parsing: {len(PARSING)} expressions, {len(failures)} failures")
    return failures


def check_plan_files():
    failures = []
    runs = run("NetlogoEarnedValueManagementV1.2.nlogox", "regression-plan-files")
    seen = set()
    for steps in runs.values():
        last = steps[-1]
        name = last["plan-override"]
        seen.add(name)
        message, tasks = PLAN_FILES[name]
        if not last["plan-error"].startswith(message) or (message == "") != (last["plan-error"] == ""):
            failures.append(f"{name}: plan-error '{last['plan-error']}', expected '{message}...'")
        if int(last["count tasks"]) != tasks:
            failures.append(f"{name}: {last['count tasks']} tasks, expected {tasks}")
        if tasks and (last[DONE] != last["count tasks"] or last["ticks"] != last["PMB-Duration"]):
            failures.append(f"{name}: expected all tasks done in exactly the planned {last['PMB-Duration']} ticks")
    for name in set(PLAN_FILES) - seen:
        failures.append(f"{name}: not run")
    print(f"regression-plan-files: {len(runs)} runs, {len(failures)} failures")
    return failures


failures = []
failures += check_parsing()
failures += check_plan_files()
failures += check("NetlogoEarnedValueManagementV1.2.nlogox", "regression-no-delay", True)
failures += check("NetlogoEarnedValueManagementV1.2.nlogox", "regression-plan-csv", True)
# demo plan with one link of each type (SS, FF, FS+%, SF, FS+days): ideal run = plan, to the tick
failures += check("NetlogoEarnedValueManagementV1.2.nlogox", "regression-link-types", True, abs_tol=1)
failures += check("NetlogoEarnedValueManagementWebV1.2.nlogox", "regression-no-delay", True)
for f in failures:
    print("FAIL", f)
sys.exit(1 if failures else 0)
