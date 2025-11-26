#!/usr/bin/env bash
# Executes a single task with timeout, retry, logging, and notifications.
set -euo pipefail         #errors not masked - strict mode

#directory variables
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
confFile="$baseDir/configs/default.conf"
[ -f "$confFile" ] && source "$confFile"

#usage instructions
usage() {
  echo "Usage: $0 <task-metadata-file> [--dry-run]"
  exit 2
}

#check if enough arguments are entered
[ $# -ge 1 ] || usage

#get task meta file
taskMetaFile="$1"

#check if dry run set
runDry=false
if [ "${2:-}" = "--dry-run" ]; then
  runDry=true
fi

#check if task meta file found
if [ ! -f "$taskMetaFile" ]; then
  echo "Task metadata file not found: $taskMetaFile" >&2
  exit 3
fi

#store task meta info into an array
#clean inputs and store as key-value pairs, reading from taskMetaFile
declare -A metaInfo
while IFS='=' read -r key value; do
  [[ $key =~ ^\s*# ]] && continue
  key=$(echo "$key" | tr -d ' \t"')
  value=$(echo "$value" | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/^"//' -e 's/"$//')
  if [ -n "$key" ]; then
    metaInfo[$key]="$value"
  fi
done < "$taskMetaFile"

#store key-value pairs as variables in program
tID="${metaInfo[tID]:-unnamedTask}"
tCOMMAND="${metaInfo[tCOMMAND]:-}"
if [ -z "$tCOMMAND" ]; then
  echo "Task $tID missing tCOMMAND in $taskMetaFile" >&2
  exit 4
fi
tTIMEOUT="${metaInfo[tTIMEOUT]:-${TIMEOUT:-30}}"
tRETRIES="${metaInfo[tRETRIES]:-${RETRIES:-3}}"
tRETRYDELAY="${metaInfo[tRETRYDELAY]:-${RETRYDELAY:-5}}"
tNOTIFYSUCCESS="${metaInfo[tNOTIFYSUCCESS]:-${NOTIFYSUCCESS:-false}}"
tNOTIFYFAILURE="${metaInfo[tNOTIFYFAILURE]:-${NOTIFYFAILURE:-true}}"

#create run id and log directory+file for current task
rID=$(date +%Y%m%d-%H%M%S)
logDirectory="${LOGS:-$baseDir/logs}/tasks/${tID}"
mkdir -p "$logDirectory"
logFile="$logDirectory/${tID}_run-${rID}.log"

#log task info into logFile
{
  echo "tID=$tID"
  echo "rID=$rID"
  echo "tCOMMAND=$tCOMMAND"
  echo "tTIMEOUT=$tTIMEOUT"
  echo "tRETRIES=$tRETRIES"
  echo "tRETRYDELAY=$tRETRYDELAY"
  echo "startTime=$(date --iso-8601=seconds)"
} > "$logFile"

#dry run simulation
if [ "$runDry" = true ]; then
  echo "[DRY RUN] Would run: $tCOMMAND"
  echo "Dry run log path: $logFile"
  exit 0
fi

#if timeout command isn't availabel
if ! command -v timeout >/dev/null 2>&1; then
  echo "timeout command not available; cannot enforce task timeout" | tee -a "$logFile" >&2
  exit 5
fi

#set max attempts and run status
maxAttempts=$((tRETRIES + 1))
status=0

#attempt the task, logging the attempt number, start/end times, and exit code
for attemptNo in $(seq 1 "$maxAttempts"); do
  echo "ATTEMPT_NO=$attemptNo" >> "$logFile"
  echo "ATTEMPT_START_TIME=$(date --iso-8601=seconds)" >> "$logFile"
  exitCode=0
  timeout --preserve-status "$tTIMEOUT" bash -c "$tCOMMAND" >> "$logFile" 2>&1 || exitCode=$?
  echo "ATTEMPT_END_TIME=$(date --iso-8601=seconds)" >> "$logFile"
  echo "ATTEMPT_EXIT_CODE=$exitCode" >> "$logFile"

  #if successful, log it and notify user if flag to notify on success set
  if [ "$exitCode" -eq 0 ]; then
    echo "END_TIME=$(date --iso-8601=seconds)" >> "$logFile"
    if [ "${tNOTIFYSUCCESS,,}" = "true" ]; then
      "$baseDir/bin/notifier.sh" --task "$tID" --status "SUCCESS" --log "$logFile" || true
    fi
    exit 0
  fi

  #if max retries not passed then retry after some time passes, otherwise exit program
  if [ "$attemptNo" -lt "$maxAttempts" ]; then
    echo "Retrying after $tRETRYDELAY seconds" >> "$logFile"
    sleep "$tRETRYDELAY"
  else
    status=$exitCode
    echo "Max retries reached. Exit code: $status" >> "$logFile"
    echo "END_TIME=$(date --iso-8601=seconds)" >> "$logFile"
    if [ "${tNOTIFYFAILURE,,}" = "true" ]; then
      "$baseDir/bin/notifier.sh" --task "$tID" --status "FAILURE" --log "$logFile" || true
    fi
    exit "$status"
  fi
done