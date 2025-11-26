#!/usr/bin/env bash
# Helper script used by sampleBad.task: fails once, then succeeds.

#directory/file variables
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flagFile="$baseDir/examples/sampleBadHelper.flag"

#create a flagFile to let the sampleBad run succeed on its second attempt
if [ ! -f "$flagFile" ]; then
  echo "First run fails intentionally"
  mkdir -p "$(dirname "$flagFile")"
  touch "$flagFile"
  exit 1
else
  echo "Second run succeeds"
  exit 0
fi