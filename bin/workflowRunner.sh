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

