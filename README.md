# Earned Value Management agent-based model (NetLogo)

An agent-based model that simulates a project being executed by a team and measures it with
Earned Value Management (EVM): Planned Value (PV), Earned Value (EV), Actual Cost (AC),
SV/CV, SPI/CPI, TCPI, estimates at completion (EAC, ETC, VAC) and an earned-schedule time
forecast (EACt). Employees pick tasks from a to-do backlog, work on them and finish them on a
task board, while tasks can be delayed or advanced at random.

## Files

| File | Purpose |
| --- | --- |
| `NetlogoEarnedValueManagementV1.1.nlogox` | Desktop model (NetLogo 7). Can load the MS Project plan and export CSV files. |
| `NetlogoEarnedValueManagementWebV1.1.nlogox` | Version for NetLogo Web: random tasks only, EVM code inlined (no `__includes`, no CSV extension). |
| `EarnedValueManagement.nls` | EVM reporters (BAC, PV, EV, AC, SPI, CPI, TCPI, EAC, ES, EACt...) included by the desktop model. |
| `input/Software-Development-Plan.csv` | Sample plan exported from MS Project (61 tasks with dates and predecessors). |
| `input/Plan-link-types.csv` | Small demo plan with one link of each type (SS, FF, FS with a percentage lag, SF, FS with a lag). |
| `output/` | Sample output of `Write tasks to tasks.csv` / `Write employees to employees.csv`. |
| `tests/check_regression.py` | Headless regression checks (see below). |
| `Software Development Plan/`, `EVM Tools/` | The original MS Project plan and EVM calculators used as references. |

## Running it

1. Open the `.nlogox` file in NetLogo 7.0.4 (or later).
2. Set the sliders: `employees-number`, `number-of-tasks`, `probability-of-delay`,
   `probability-of-advance`, `assigned-tasks-employee` and `dependency-probability`.
3. Press `setup`, then `go` (or `step-go`).
4. To use the MS Project plan instead of random tasks, switch `load-file` on before `setup`
   (desktop version only).

### How a task is simulated

- Every hour worked costs one hour of AC, whether or not it produces progress.
- With `probability-of-delay` the hour is lost (no progress). With `probability-of-advance`
  the task progresses one extra hour at no extra cost.
- An employee works at most `assigned-tasks-employee` tasks at a time and picks one new task
  per tick. A task can only be picked when all its predecessors are done.

### The plan (baseline)

Both task sources have a planned start and finish for every task, so PV is time-phased:
each task earns its planned hours linearly between its start and finish, and
`PMB-Duration` is the finish of the last task. 1 tick = 1 working hour.

- **Random tasks**: each task gets, with probability `dependency-probability`, 1 to 3
  predecessors among the tasks created before it. The plan comes from an ideal run with no
  delay or advance and `employees-number * assigned-tasks-employee` parallel slots.
- **MS Project CSV**: dates are converted to working hours (8 h per business day,
  8:00-12:00 and 1:00-5:00, no weekends). The four relation types are supported, each with a lag
  or lead in days, hours, weeks or minutes, or as a percentage of the predecessor's duration:
  `FS` and `SS` gate the start of the task (after the predecessor finishes or starts), `FF` and
  `SF` gate its completion (the task can work, but cannot finish before the predecessor finishes
  or starts). A lead on `FS`/`FF` (for example `FS-11.25 days`) holds once the predecessor has
  that many hours of work left. Resource names are ignored, so any employee can pick any task,
  and the simulated project can still differ slightly from the plan (about 1.6% in the sample
  plan with no delay or advance). Choose the plan with the `plan-file` chooser.

The Info tab of the model documents every metric and formula.

## Output files

- `Write tasks to tasks.csv`: one row per task with its plan (`start-tick`, `finish-tick`),
  completion ratio, actual hours and `predecessors` (task numbers).
- `Write employees to employees.csv`: one row per employee.

Both files have a header row and are written to `output/`.

## Tests

`tests/check_regression.py` runs the `regression-no-delay`, `regression-plan-csv` and
`regression-link-types` BehaviorSpace experiments of the models headless and checks that all tasks finish, that no
task starts before its predecessors are done, and that, with no delay or advance, the real
duration is close to the planned one.

    python3 tests/check_regression.py "/Applications/NetLogo 7.0.4"

## License

See `LICENSE.md`.
