#!/usr/bin/env bash
# Notification wrapper using mailx (or configured mailer).
set -euo pipefail         #errors not masked - strict mode

#directory variables
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
confFile="$baseDir/configs/default.conf"
[ -f "$confFile" ] && source "$confFile"

#usage instructions
usage() {
  echo "Usage: $0 --task <tID> --status <SUCCESS|FAILURE> --log <logFile> [--to <email>] [--dry-run]"
  exit 2
}

#initalizer variables
mailTo=""
mailTask=""
mailStatus=""
logFile=""
dryRun=false

#parse and store input variables
while [ $# -gt 0 ]; do
  case "$1" in
    --task) mailTask="$2"; shift 2;;
    --status) mailStatus="$2"; shift 2;;
    --log) logFile="$2"; shift 2;;
    --to) mailTo="$2"; shift 2;;
    --dry-run) dryRun=true; shift;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

#mandatory variables - if not provided, show usage instructions again
[ -n "$mailTask" ] || usage
[ -n "$mailStatus" ] || usage
[ -n "$logFile" ] || usage

#define mail subject, recipient, and body
mailSubj="[Scheduler] Task $mailTask - $mailStatus"
mailTo="${mailTo:-${MAILTO:-person@example.com}}"
mailBody="Task: $mailTask\nStatus: $mailStatus\nLog: $logFile\n\nLast 50 lines of log:\n\n$(tail -n 50 "$logFile" 2>/dev/null || true)"

#dry run simulation
if [ "$dryRun" = true ]; then
  echo "[DRY RUN] Would send email to $mailTo with subject: $mailSubj"
  exit 0
fi

#performs mail operation/error handling
mailer="${MAILCMD:-mailx}"
if command -v "$mailer" >/dev/null 2>&1; then
  printf "%b" "$mailBody" | "$mailer" -s "$mailSubj" "$mailTo"
else
  echo "Mailer not found: $mailer" >&2
  exit 4
fi