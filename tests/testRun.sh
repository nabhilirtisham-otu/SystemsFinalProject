#!/usr/bin/env bash
# Overall test harness
set -euo pipefail

#directory variables
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
binDir="$baseDir/bin"

#runs sampleGood task
echo "Running sampleGood.task (succeeds)"
"$binDir/taskRunner.sh" "$baseDir/tasks/sampleGood.task"

#runs sampleBad task
echo "Running sampleBad.task (fails once, then succeeds w/ retries)"
"$binDir/taskRunner.sh" "$baseDir/tasks/sampleBad.task"

#runs sampleFlow workflow
echo "Running sampleFlow.workflow"
"$binDir/workflowRunner.sh" "$baseDir/workflows/sampleFlow.workflow"
