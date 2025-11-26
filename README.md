# SystemsFinalProject

Task scheduling and workflow runner implemented in Bash with cron integration, logging, retries, and email notifications.

## Prerequisites
- Bash + `timeout`, `crontab`
- Optional: `mailx` (or another mailer configured in `configs/default.conf`)

## Setup and Installation
```bash
git clone <repo>
cd SystemsFinalProject
chmod +x bin/*.sh examples/*.sh tests/*.sh
```
Update `configs/default.conf` if you want different BASE/LOGS paths or a different mailer/recipient.

## Usage
- Create a task: `bin/CLI.sh create-task mytask` (edit `tasks/mytask.task` as needed)
- Run a task now: `bin/CLI.sh run-task mytask`
- Create a workflow: `bin/CLI.sh create-workflow myflow` (list task IDs space-separated in `wTASKS`)
- Run a workflow: `bin/CLI.sh run-workflow myflow`
- Schedule task/workflow: `bin/scheduler.sh --id mytask --schedule '0 * * * *'`
- Remove schedule: `bin/scheduler.sh --id mytask --remove`
- Dry run (no changes): add `--dry-run` to scheduler/taskRunner/workflowRunner/notifier.

## Error Handling & Logging
- Strict `set -euo pipefail` in scripts
- Task retries with timeout and delay (per-task overrides; defaults in `configs/default.conf`)
- Per-run logs under `logs/tasks/<taskId>/` and `logs/workflows/<workflowId>/`
- Missing metadata, missing commands, missing cron, or missing timeout exit with clear errors
- Notifications on success/failure (task) or completion (workflow) via `bin/notifier.sh`

## Testing
Run bundled smoke tests: `tests/testRun.sh` (executes sampleGood, sampleBad with retries, and sampleFlow workflow).