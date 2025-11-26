#!/usr/bin/env bash
#CLI for user interactions
set -euo pipefail           #Error-handling options (strict)

#Initialize directory variables
baseDir="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject"         #Root folder where project located
taskDir="$baseDir/tasks"                  #Task metadata file folder location
workflowDir="$baseDir/workflows"              #Workflow definition file folder location

#Define usage instructions - here-document, expand script name, show available subcommands
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
  exit 2            #Usage error exit code
}

#Get and store first positional argument, move all args left
userCMD="${1:-}"; shift || true         #userCMD holds subcommand, remaining args in other variables

case "$userCMD" in              #Do different things based on provided user command
    create-task)
        tID="$1"; shift || { echo "Missing ID"; exit 2; }        #Take next arg as task ID, shift args, error handling
        tFile="$taskDir/${tID}.task"                 #Build path for new task file
        if [ -f "$tFile" ]; then echo "Task exists: $tFile"; exit 1; fi         #Check if file w/ provided name already exist, prints it if so

        cat > "$tFile" <<TASK                #Start here-doc, redirecting contents into tFile, write task info into task file
tID=$tID
tDESC="User-created task $tID"
tCOMMAND="echo Running $tID"
tTIMEOUT=30
tRETRIES=1
tRETRYDELAY=5
tNOFIYSUCCESS=false
tNOTIFYFAILURE=true
TASK
        echo "Created $tFile"               #Confirmation message
        ;;

    create-workflow)
        wID="$1"; shift || { echo "Missing ID"; exit 2; }        #Take next arg as workflow ID, shift args, error handling
        wFile="$workflowDir/${wID}.workflow"                 #Build path for new workflow file
        if [ -f "$wFile" ]; then echo "Workflow exists"; exit 1; fi         #Check if file w/ provided name already exist, prints it if so

        cat > "$wFile" <<WF                #Start here-doc, redirecting contents into wFile, write workflow info into workflow file
wID=$wID
wDESC="User-created workflow $wID"
wTASKS=""
wCONTINUEFAIL=false
wNOTIFYCOMPLETE=false
WF
        echo "Created $wFile"
        ;;

    list-tasks)
        ls -1 "$taskDir"/*.task 2>/dev/null || echo "No tasks found"            #List every .task file on its own line, error handling
        ;;

    list-workflows)
        ls -1 "$workflowDir"/*.workflow 2>/dev/null || echo "No workflows found"                    #List every .workflow file on its own line, error handling
        ;;
    
    run-task)
        tID="$1"; shift || { echo "Missing ID"; exit 2; }           #Get task ID and shift args, error handling
        /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/taskRunner.sh "$taskDir/${tID}.task"            #Call task runner script, w/ full path to task metadata file
        ;;
        
    run-workflow)
        wID="$1"; shift || { echo "Missing ID"; exit 2; }           #Get workflow ID and shift args, error handling
        /mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/workflowRunner.sh "$workflowDir/${wID}.workflow"            #Call workflow runner script, w/ full path to workflow metadata file
        ;;
    
    show-task)
        tID="$1"; shift || { echo "Missing ID"; exit 2; }           #Get task ID and shift args, error handling
        cat "$taskDir/${tID}.task"              #Print contents of specified task file
        ;;

    show-workflow)
        wID="$1"; shift || { echo "Missing ID"; exit 2; }           #Get workflow ID and shift args, error handling
        cat "$workflowDir/${wID}.workflow"              #Print contents of specified workflow file
        ;;
    
    *)          #Default
        usage ;;
esac