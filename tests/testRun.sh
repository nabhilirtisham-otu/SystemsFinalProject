#!/usr/bin/env bash
#Overall test harness
set -euo pipefail           #Error-handling options (strict)

baseDir="/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject"              #Points to root dir
binDir="$baseDir/bin"                   #Point to bin folder in project

#Runs successful task
echo "Running sampleGood.task (succeeds)"
$binDir/taskRunner.sh "$baseDir/tasks/sampleGood.task"

#Runs failing task
echo "Running sampleBad.task (fails once, then succeeds w/ retries)"
$binDir/taskRunner.sh "$baseDir/tasks/sampleBad.task"

#Runs sequential workflow
echo "Running sampleFlow.workflow"
$binDir/workflowRunner.sh "$baseDir/workflows/sampleFlow.workflow"