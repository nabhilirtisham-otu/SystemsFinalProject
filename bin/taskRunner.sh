# This script executes a task - includes timeout, retrying, and logging functionality

set -euo pipefail

# Load the configuration file defined in configs/default.conf
SELFDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"			# Directory of the current file
CONFIG="/mnt/c/Users/Nabhi/SystemsFinalProject/configs/default.conf"
if [ -f "$CONFIG" ]; then						# If the CONFIG file exists, execute it
	source "$CONFIG"
fi

# Defines how the file should be used, optionally letting users specify it to be a dry run
defineUsage(){
	echo "Usage: $0 <task-metadata-file> [--dry-run]"
	exit 2
}

# Error handling if an insufficient number of arguments are provided
if [ $# -lt 1 ]; then
	usage
fi

# Stores the meta file and sets whether the command is a dry run or not
taskMetaFile="$1"
runDry=false
if [ "${2:-}" == "--dry-run"]; then
	runDry=true
fi
