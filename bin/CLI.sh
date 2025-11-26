#!/usr/bin/env bash
# CLI for user interactions
set -euo pipefail         #errors not masked - strict mode

#directory variables for base, tasks, and workflows
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
taskDir="$baseDir/tasks"
workflowDir="$baseDir/workflows"

#usage instructions
usage() {
  cat <<EOF
Usage: $0 <command> [args]

Commands:
  create-task <id>        Create task metadata
  create-workflow <id>    Create workflow metadata
  list-tasks              List all tasks
  list-workflows          List all workflows
  run-task <id>           Execute a task immediately
  run-workflow <id>       Execute a workflow immediately
  show-task <id>          Display raw task file
  show-workflow <id>      Display raw workflow file
EOF
  exit 2
}

#takes user command to perform
userCMD="${1:-}"; shift || true

#performs different things based on user command input
case "$userCMD" in
  create-task)
    tID="${1:-}"; shift || { echo "Missing ID"; exit 2; }     #Creates task, error handling for ID
    [ -n "$tID" ] || { echo "Missing ID"; exit 2; }
    tFile="$taskDir/${tID}.task"                              #Check if task exists
    if [ -f "$tFile" ]; then echo "Task exists: $tFile"; exit 1; fi

    cat > "$tFile" <<TASK                                     #Here-document to set task details
tID=$tID
tDESC="User-created task $tID"
tCOMMAND="echo Running $tID"
tTIMEOUT=30
tRETRIES=1
tRETRYDELAY=5
tNOTIFYSUCCESS=false
tNOTIFYFAILURE=true
TASK
    echo "Created $tFile"
    ;;

  create-workflow)
    wID="${1:-}"; shift || { echo "Missing ID"; exit 2; }     #Same as above but for workflows
    [ -n "$wID" ] || { echo "Missing ID"; exit 2; }
    wFile="$workflowDir/${wID}.workflow"
    if [ -f "$wFile" ]; then echo "Workflow exists"; exit 1; fi

    cat > "$wFile" <<WF
wID=$wID
wDESC="User-created workflow $wID"
wTASKS=""
wCONTINUEFAIL=false
wNOTIFYCOMPLETE=false
WF
    echo "Created $wFile"
    ;;

  list-tasks)
    ls -1 "$taskDir"/*.task 2>/dev/null || echo "No tasks found"      #List tasks and workflows
    ;;

  list-workflows)
    ls -1 "$workflowDir"/*.workflow 2>/dev/null || echo "No workflows found"
    ;;

  run-task)
    tID="${1:-}"; shift || { echo "Missing ID"; exit 2; }             #Run task and workflows
    [ -n "$tID" ] || { echo "Missing ID"; exit 2; }
    "$baseDir/bin/taskRunner.sh" "$taskDir/${tID}.task"
    ;;

  run-workflow)
    wID="${1:-}"; shift || { echo "Missing ID"; exit 2; }
    [ -n "$wID" ] || { echo "Missing ID"; exit 2; }
    "$baseDir/bin/workflowRunner.sh" "$workflowDir/${wID}.workflow"
    ;;

  show-task)
    tID="${1:-}"; shift || { echo "Missing ID"; exit 2; }             #Display all current tasks and workflows
    [ -n "$tID" ] || { echo "Missing ID"; exit 2; }
    cat "$taskDir/${tID}.task"
    ;;

  show-workflow)
    wID="${1:-}"; shift || { echo "Missing ID"; exit 2; }
    [ -n "$wID" ] || { echo "Missing ID"; exit 2; }
    cat "$workflowDir/${wID}.workflow"
    ;;

  *)
    usage ;;        #default
esac