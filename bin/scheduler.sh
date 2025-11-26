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

