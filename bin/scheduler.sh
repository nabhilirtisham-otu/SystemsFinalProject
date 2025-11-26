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

