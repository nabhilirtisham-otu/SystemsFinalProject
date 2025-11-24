#Executes a task - incl. timeout, retrying, logging functionality

set -euo pipefail

#Load configuration file defined in configs/default.conf
SELFDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"			# Directory of the current file
CONFIG="/mnt/c/Users/Nabhi/SystemsFinalProject/configs/default.conf"
if [ -f "$CONFIG" ]; then						# If the CONFIG file exists, execute it
	source "$CONFIG"
fi

#Defines how the file should be used, optionally letting users run a dry run
defineUsage(){
	echo "Usage: $0 <task-metadata-file> [--dry-run]"
	exit 2
}

#Error handling if insufficient # of arguments provided
if [ $# -lt 1 ]; then
	usage
fi

#Stores meta file, sets if command is dry run or not
taskMetaFile="$1"
runDry=false
if [ "${2:-}" == "--dry-run"]; then
	runDry=true
fi

#Error handling if specified task metadata file isn't found
#Redirects output to stderr, exits w/ code 3 to indicate invalid path
if [ ! -f "$taskMetaFile" ]; then
	echo "Task metadata file not found: $taskMetaFile">&2
	exit 3
fi

#Reads .task metadata file, stores its info in key-value pairs
declare -A metaInfo							#Declare indexed associative array	
while IFS='=' read -r key value; do					#Read lines, elements before '=' go in key, after in value
	[[ $key =~ ^\s*# ]] continue					#Read lines literally, ignore comments
	key=$(echo "$key" | tr -d ' \t"')				#Remove spaces, tabs, + quotes
	value=$(echo "$value" | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/^"//' -e 's/"$//') 	#Removes leading/trailing spaces + quotes
	if [ -n "$key" ]; then						#Stores key-value in array only if non-empty
		metaInfo[$key]="$value"
	fi
done < "$taskMetaFile"							#Loop reads from taskMetaFile

#Map array values into local vars.
tID="${metaInfo[tID]:-unnamedTask}"
tCOMMAND="${metaInfo[tCOMMAND]}"
tTIMEOUT="${metaInfo[tTIMEOUT]:-${defaultTIMEOUT:-30}}"
tRETRIES="${metaInfo[tRETRIES]:-${defaultRETRIES:-3}}"
tRETRYDELAY="${metaInfo[tRETRYDELAY]:-${defaultRETRYDELAY:-5}}"
tNOTIFYSUCCESS="${metaInfo[tNOTIFYSUCCESS]:-${defaultNOTIFYSUCCESS:-false}}"
tNOTIFYFAILURE="${metaInfo[tNOTIFYFAILURE]:-${defaultNOTIFYFAILURE:-true}}"

#Creates id for current run, stores it in log file
rID=$(date +%Y%m%d-%H%M%S)
logDirectory="${LOGS:-/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject}/logs/tasks/${tID}"	# Creates the directory for log files
mkdir -p "$logDirectory"
logFile="$logDirectory/${tID}run-${ID}.log"							# Creates the logFile 

#Logs run info in log file
echo "tID=$tID" > "${logFile}"
echo "rID=$rID" > "${logFile}"
echo "tCOMMAND=$tCOMMAND" > "${logFile}"
echo "tTIMEOUT=$tTIMEOUT" > "${logFile}"
echo "tRETRIES=$tRETRIES" > "${logFile}"
echo "tRETRYDELAY=$tRETRYDELAY" > "${logFile}"
echo "startTime=$(date --iso-8601=seconds)" >> "${logFile}"

#Prints dry run output
if [ "$runDry" == true ]; then
	echo "A dry run would run: ${tCOMMAND}"
	echo "Dry run log path: ${logFile}"
	exit 0
fi

attempt=0
exitCode=0
while [ $attempt -le "$tRetries" ]; do				#Checks if the current attempt number is not over the max amount of tries
	attempt=$((attempt+1))							#Increment attempt counter
