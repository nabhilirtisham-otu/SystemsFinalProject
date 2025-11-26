#!/usr/bin/env bash
# Executes tasks in a workflow with optional continue-on-fail and notifications.
set -euo pipefail         #errors not masked - strict mode

#directory variables
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
confFile="$baseDir/configs/default.conf"
[ -f "$confFile" ] && source "$confFile"

#usage instructions
usage() {
  echo "Usage: $0 <workflow-file> [--dry-run]"
  exit 2
}

#checks if enough arguments provided
[ $# -ge 1 ] || usage

#get workflow metafile
wFILE="$1"

#set dry run flag
dryRun=false
if [ "${2:-}" = "--dry-run" ]; then
  dryRun=true
fi

#if workflow file not found
if [ ! -f "$wFILE" ]; then
  echo "Workflow file not found: $wFILE" >&2
  exit 3
fi

#declare array and store sanitized key-value pairs
declare -A wflow
while IFS='=' read -r key value; do
  [[ $key =~ ^\s*# ]] && continue
  key=$(echo "$key" | tr -d ' \t"')
  value=$(echo "$value" | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/^"//' -e 's/"$//')
  if [ -n "$key" ]; then
    wflow[$key]="$value"
  fi
done < "$wFILE"

#store workflow ID, tasks within the workflow, and workflow flags
wID="${wflow[wID]:-unnamedWf}"
taskStr="${wflow[wTASKS]:-}"
IFS=' ' read -r -a wTASKS <<< "$taskStr"
wCONTINUEFAIL="${wflow[wCONTINUEFAIL]:-false}"
wNOTIFYCOMPLETE="${wflow[wNOTIFYCOMPLETE]:-false}"

#set run id and create log directory+file for workflow
rID=$(date +%Y%m%d-%H%M%S)
logDir="${LOGS:-$baseDir/logs}/workflows/${wID}"
mkdir -p "$logDir"
logFile="$logDir/${wID}_run-${rID}.log"

#log workflow information
{
  echo "wID=$wID"
  echo "rID=$rID"
  echo "wTASKS=${wTASKS[*]}"
  echo "startTime=$(date --iso-8601=seconds)"
} > "$logFile"

#dry run simulation
if [ "$dryRun" = true ]; then
  echo "[DRY RUN] Workflow $wID tasks: ${wTASKS[*]}"
  echo "Log path: $logFile"
  exit 0
fi

#run and log tasks in workflow
status=0
for t in "${wTASKS[@]}"; do
  echo "Running task: $t" >> "$logFile"
  taskMeta="$baseDir/tasks/${t}.task"

  #if task metadata not found
  if [ ! -f "$taskMeta" ]; then
    echo "Task metadata missing: $taskMeta" >> "$logFile"
    status=2
    if [ "${wCONTINUEFAIL,,}" = "false" ]; then
      echo "Aborting workflow due to missing task." >> "$logFile"
      break
    else
      continue
    fi
  fi

  #retrieve and log task/workflow return code
  returnCode=0
  "$baseDir/bin/taskRunner.sh" "$taskMeta" || returnCode=$?
  echo "tRETURNCODE=$returnCode" >> "$logFile"

  #log and display
  if [ "$returnCode" -ne 0 ]; then
    status=1
    if [ "${wCONTINUEFAIL,,}" = "false" ]; then
      echo "Task failed and workflow stops on failure." >> "$logFile"
      break
    fi
  fi
done

#record workflow end time and status
echo "END_TIME=$(date --iso-8601=seconds)" >> "$logFile"
echo "STATUS=$status" >> "$logFile"

#display success/error message
if [ "${wNOTIFYCOMPLETE,,}" = "true" ]; then
  finalStatus=$([ "$status" -eq 0 ] && echo "SUCCESS" || echo "FAILURE")
  "$baseDir/bin/notifier.sh" --task "$wID" --status "$finalStatus" --log "$logFile" || true
fi

#exit with status code
exit $status