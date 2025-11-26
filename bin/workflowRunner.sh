#!/usr/bin/env bash
#Executes tasks in a workflow
set -euo pipefail           #Error-handling options (strict)

#Checks if config file exists, loads it if it does
confFile="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/configs/default.conf"
if [ -f "$confFile" ]; then
  source "$confFile"
fi

#Function to display usage information
usage() {
  echo "Usage: $0 <workflow-file> [--dry-run]"
  exit 2
}

#If less than 1 arg provided, display usage info
if [ $# -lt 1 ]; then
  usage
fi

wFILE="$1"              #Path to workflow definition file
dryRun=false            #Dry run flag default false
if [ "${2:-}" == "--dry-run" ]; then            #Set dry run flag to true if specified so
  dryRun=true
fi

#Check if workflow file exists, print error message if not
if [ ! -f "$wFILE" ]; then
  echo "Workflow file not found: $wFILE" >&2
  exit 3
fi

#Read workflow metadata
declare -A wflow                    #Associative array storing workflow properties read from file
while IFS='=' read -r key value; do             #Read workflow line by line, parse into wf array
  [[ $key =~ ^\s*# ]] && continue               #Ignore comment line
  key=$(echo "$key" | tr -d ' \t"')             #Strip spaces, tabs, double-quotes
  value=$(echo "$value" | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/^"//' -e 's/"$//')          #Remove whitespace, double-quotes (clean value string)
  if [ -n "$key" ]; then                #Process key if non-empty
    wflow[$key]="$value"                #Store key-value pair in wflow
  fi
done < "$wFILE"                 #Loop to read from workflow file

wID="${wflow[wID]:-unnamedWf}"          #Read workflow id from wflow, default to unnamedWf
taskStr="${wflow[wTASKS]:-}"               #Read tasks field, default to empty string
IFS=' ' read -r -a wTASKS <<< "$taskStr"            #Set field separator to space, split string into TASKS array, feed string to read
wCONTINUEFAIL="${wflow[wCONTINUEFAIL]:-false}"              #Sets wCONTINUEFAIL, wNOTIFYCOMPLETE flags (default to false)
wNOTIFYCOMPLETE="${wflow[wNOTIFYCOMPLETE]:-false}"

rID=$(date +%Y%m%d-%H%M%S)              #Run id timestamp
logDir="${logDir:-/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/}/workflows/${wID}"          #Use log directory from config, default to root file prefix otherwise
mkdir -p "$logDir"              #Create log directory for specific workflow
logFile="$logDir/${wID}_run-${rID}.log"             #Log file path for current workflow run

#Initial log header - log workflow id being run, run id, tasks in workflow, start time
echo "wID=$wID" > "$logFile"
echo "rID=$rID" >> "$logFile"
echo "wTASKS=${wTASKS[*]}" >> "$logFile"
echo "startTime=$(date --iso-8601=seconds)" >> "$logFile"

#Dry run simulation
if [ "$dryRun" = true ]; then
  echo "[DRY RUN] Workflow $wID tasks: ${wTASKS[*]}"
  echo "Log path: $logFile"
  exit 0
fi

status=0                #Workflow overall status
for t in "${wTASKS[@]}"; do          #For every tID in the wTASKS array
  echo "Running task: $t" >> "$logFile"             #Log task being run
  taskMeta="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/tasks/${t}.task"           #Path to task metadata file

  if [ ! -f "$taskMeta" ]; then             #Check if task metadata file exists
    echo "Task metadata missing: $taskMeta" >> "$logFile"           #Display and log error
    status=2
    if [ "${wCONTINUEFAIL,,}" = "false" ]; then             #Check if workflow can keep going if task is missing
      echo "Aborting workflow due to missing task." >> "$logFile"               #If not, abort workflow
      break
    else
      continue                  #Continue otherwise
    fi
  fi

  #Run task and capture exit code, catprures error w/o exiting entire script, error handling if rc=$? (store exit code) fails
  /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/taskRunner.sh "$TASK_META" || returnCode=$? || returnCode=0
  returnCode=${returnCode:-0}               #Set default code to 0

  echo "tRETURNCODE=$returnCode" >> "$logFile"              #Log task return code

  if [ "$returnCode" -ne 0 ]; then                  #If task failed
    status=1                    #Mark as having at least one failed task
    if [ "${wCONTINUEFAIL,,}" = "false" ]; then                 #If not allowed to continue after failure
      echo "Task failed and workflow stops on failure." >> "$logFile"               #Log workflow stoppage due to failure
      break
    fi
  fi
done

echo "ATTEMPT_END_TIME=$(date --iso-8601=seconds)" >> "$logFile"                #Log workflow ending time
echo "STATUS=$status" >> "$logFile"                #Log finall overall status

#Notify upon completion if set, provide wID, status, and logFile path
if [ "${wNOTIFYCOMPLETE,,}" = "true" ]; then
  if command -v /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/notifier.sh >/dev/null 2>&1; then
    /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/notifier.sh --task "$wID" --status "$status" --log "$logFile" || true
  fi
fi

exit $status                #Exit w/ workflow overall status