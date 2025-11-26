#!/usr/bin/env bash
#helper script registering tasks/workflows into users crontab
set -euo pipefail           #Error-handling options (strict)

#Checks if config file exists, loads it if it does
confFile="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/configs/default.conf"
if [ -f "$confFile" ]; then
  source "$confFile"
fi

#Define usage instructions
usage() {
  echo "Usage: $0 --id <task/workflow-id> --schedule '<cron expr>' [--remove] [--dry-run] [--system]"
  exit 2
}

#Variable initialization
twID=""             #task/workflow ID passed in
crSCHEDULE=""       #hold cron expression string
crREMOVE=""         #set if removing/adding cron entry
dryRun=false        #Dry run flag
userCron=true       #Modify user crontab, write to system-wide crontab otherwise

#Read CL arguments
while [ $# -gt 0 ]; do          #While at least one arg left
  case "$1" in                  #Check what current first arg is
    --id) twID="$2"; shift 2;;          #If task/workflow ID, set twID to next argument (task/workflow ID value)
    --schedule) crSCHEDULE="$2"; shift 2;;      #Same as above for cron expression string
    --remove) crREMOVE=true; shift;;            #Same as above for cron entry addition/removal
    --dry-run) dryRun=true; shift;;         #Same as above for dry run flag
    --system) userCron=false; shift;;       #Same as above for user/system cron writing
    *) usage;;                  #Check if invalid arg provided, display usage if so
  esac
done

#Error handling for variables
[ -n "$twID" ] || usage           #task/work ID must be provided
if [ "$crREMOVE" = false ] && [ -z "$crSCHEDULE" ]; then        #If not in remove mode and schedule not provided, print error message and display usage
  echo "Missing install schedule."
  usage
fi

#Assume twID refers to workflow, create command running workflowRunner script on workflows directory
crCMD="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/workflowRunner.sh /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/workflows/${twID}.workflow"

if [ -f "/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/tasks/${twID}.task" ]; then       #If task metadata file exists w/ provided ID
  CMD="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/taskRunner.sh /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/tasks/${twID}.task"          #Run taskRunner instead
fi

crENTRY="$crSCHEDULE $crCMD >/dev/null 2>&1"        #Build actual cron line

#Simulate dry run results
if [ "$dryRun" = true ]; then
  echo "[DRY RUN] Cron entry: $crENTRY"
  exit 0
fi

#Remove mode logic
if [ "$crREMOVE" = true ]; then
  crontab -l | grep -v -F "$crCMD" | crontab -          #Take existing user crontab, filter out lines w/ command string, read updated lines from stdin, install as new crontab
  echo "Cron entry removed for $twID."              #Print confirmation
  exit 0
fi

#Install into user/system cron
if [ "$userCron" = true ]; then         #Check if using user personal crontab
  (crontab -l 2>/dev/null | grep -v -F "$crCMD" || true; echo "$crENTRY") | crontab -          #List current crontab (errors redirected), remove existing line using same command, appends new cronline, installs updated crontab
  echo "Installed user cron entry."
else
  if [ ! -w /etc/cron.d ]; then         #Check if permission to write to /etc/cron.d given
    echo "Cannot write to /etc/cron.d (need root privileges)." >&2          #Error message if not
    exit 1
  fi
  echo "$crENTRY" > "/etc/cron.d/task_scheduler_${twID}"            #Write cron file in /etc/cron.d w/ name based on twID, define scheduled job for cron to do
  echo "Installed system cron entry /etc/cron.d/task_scheduler_${twID}"
fi