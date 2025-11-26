#!/usr/bin/env bash
# notification wrapper using mailx
set -euo pipefail           #Error-handling options (strict)

#Checks if config file exists, loads it if it does
confFile="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/configs/default.conf"
if [ -f "$confFile" ]; then
  source "$confFile"
fi

#Define usage function, explain how to run script
usage() {
  echo "Usage: $0 --task <tID> --status <SUCCESS|FAILURE> --log <logFile> [--to <email>] [--dry-run]"
  exit 2
}

#Variables to store command-line options
mailTo=""           #Who mail is sent to
mailTask=""         #Task specified in mail
mailStatus=""       #Mail sent status (success/failure)
logFile=""          #Log file path
dryRun=false        #Flag if run is dry

#Process CL arguments one by one
while [ $# -gt 0 ]; do          #While at least one arg left
  case "$1" in                  #Check what current first arg is
    --task) mailTask="$2"; shift 2;;        #If task, set mailTask to next argument (task value)
    --status) mailStatus="$2"; shift 2;;        #If status, set mailStatus to next argument (status value)
    --log) logFile="$2"; shift 2;;      #If logFile, set logFile to next argument (logFile value)
    --to) mailTo="$2"; shift 2;;        #If mail recipient, set mailTo to the next argument (receipient value)
    --dry-run) dryRun=true; shift;;     #If --dry-run, set dry run flag to next argument (dry run value)
    *) echo "Unknown arg: $1"; usage;;      #If invalid argument, display usage instructions
  esac
done

#If mail task, status, or logfile path are empty, display usage instructions (required variables, can't  be empty)
[ -n "$mailTask" ] || usage
[ -n "$mailStatus" ] || usage
[ -n "$logFile" ] || usage

mailSubj="[Scheduler] Task $mailTask - $mailStatus"         #Email subject string
mailTo="${mailTo:-person@example.com}"                 #Default person to mail to, if mailTo is empty
mailBody="Task: $mailTask\nStatus: $mailStatus\nLog: $logFile\n\nLast 50 lines of log:\n\n$(tail -n 50 "$logFile" 2>/dev/null || true)"     #mail body, contains task, status, logfile, last 50 lines of logfile

#Simulate dry run results
if [ "$dryRun" = true ]; then
  echo "[DRY RUN] Would send email to $mailTo with subject: $mailSubj"
  exit 0
fi

#Send email or throw error message
if command -v "$MAILCMD" >/dev/null 2>&1; then          #Check if mail command exists on system (suppress output)
  printf "%b" "$mailBody" | "$MAILCMD" -s "$mailSubj" "$mailTo"         #Print body string, pipe into mail command
else
  echo "Mailer not found: $MAILCMD" >&2             #Error handling if mailer not found
  exit 4                #Error code for mail error
fi