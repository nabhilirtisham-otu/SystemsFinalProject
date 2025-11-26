#!/usr/bin/env bash
# Registers tasks/workflows into cron (user or system).
set -euo pipefail         #errors not masked - strict mode

#directory variables
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
confFile="$baseDir/configs/default.conf"
[ -f "$confFile" ] && source "$confFile"    #configure source file

#usage instructions
usage() {
  echo "Usage: $0 --id <task/workflow-id> --schedule '<cron expr>' [--remove] [--dry-run] [--system]"
  exit 2
}

#initialize variables (task/work ID, cron schedule, etc.)
twID=""
crSCHEDULE=""
crREMOVE=false
dryRun=false
userCron=true

#while enough arguments are provided, parse input variables and shift arguments left
while [ $# -gt 0 ]; do
  case "$1" in
    --id) twID="$2"; shift 2;;
    --schedule) crSCHEDULE="$2"; shift 2;;
    --remove) crREMOVE=true; shift;;
    --dry-run) dryRun=true; shift;;
    --system) userCron=false; shift;;
    *) usage;;
  esac
done

#Error handling if task/work ID not given
[ -n "$twID" ] || usage

#if in remove mode and schedule isn't provided, display error
if [ "$crREMOVE" = false ] && [ -z "$crSCHEDULE" ]; then
  echo "Missing install schedule."
  usage
fi

#run task or workflow using their respective runners
taskMeta="$baseDir/tasks/${twID}.task"
workflowMeta="$baseDir/workflows/${twID}.workflow"
if [ -f "$taskMeta" ]; then
  crCMD="$baseDir/bin/taskRunner.sh $taskMeta"
elif [ -f "$workflowMeta" ]; then
  crCMD="$baseDir/bin/workflowRunner.sh $workflowMeta"
else
  echo "No task or workflow found for id: $twID" >&2
  exit 3
fi

#initialize cron entry
crENTRY="$crSCHEDULE $crCMD >/dev/null 2>&1"

#dry run simulation
if [ "$dryRun" = true ]; then
  echo "[DRY RUN] Cron entry: $crENTRY"
  exit 0
fi

#if crontab command not found
if ! command -v crontab >/dev/null 2>&1; then
  echo "crontab command not available; cannot install schedule" >&2
  exit 4
fi

#remove mode, remove cron entries for a task
if [ "$crREMOVE" = true ]; then
  crontab -l 2>/dev/null | grep -v -F "$crCMD" | crontab -
  echo "Cron entry removed for $twID."
  exit 0
fi

#writing into user cron tab vs system cron tab
if [ "$userCron" = true ]; then
  (crontab -l 2>/dev/null | grep -v -F "$crCMD" || true; echo "$crENTRY") | crontab -
  echo "Installed user cron entry."
else
  if [ ! -w /etc/cron.d ]; then
    echo "Cannot write to /etc/cron.d (need root privileges)." >&2
    exit 1
  fi
  echo "$crENTRY" > "/etc/cron.d/task_scheduler_${twID}"
  echo "Installed system cron entry /etc/cron.d/task_scheduler_${twID}"
fi