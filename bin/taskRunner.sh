#Executes a task - incl. timeout, retrying, logging functionality

set -euo pipefail			#Strict mode to help catch errors (script fails faster and doesn't hide bugs)

#Load configuration file defined in configs/default.conf
SELFDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"			# Directory of the current file
confFile="/mnt/c/Users/Nabhi/SystemsFinalProject/configs/default.conf"
if [ -f "$confFile" ]; then						# If config file exists, execute it
	source "$confFile"
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

attemptNo=0
exitCode=0
while [ $attemptNo -le "$tRetries" ]; do				#Checks if current attempt number isn't over max amount of tries allowed
	attempt=$((attempt+1))							#Increment attempt counter
	echo "ATTEMPT NO: $attemptNo" >> "$logFile"				#Log attempt info.
	echo "ATTEMPT_START_TIME=$(date --iso-8601=seconds)" >> "$logFile"
	timeout --preserve-status "$tTIMEOUT" bash -c "$tCOMMAND" >> "$logFile" 2>&1 || exitCode=$?			#Execute user command (max "timeout" time to run), redirect stdout/stderr into log file and capture exit code if it fails
	echo "ATTEMPT_END_TIME=$(date --iso-8601=seconds)" >> "$logFile"			#Log timestamp of attempt finish time
	echo "ATTEMPT_EXIT_CODE=$exitCode" >> "$logFile"			#Log attempt exit code

	if [ "$exitCode" -eq 0 ]; then				#If command successful
		echo "ATTEMPT_END_TIME=$(date --iso-8601=seconds)" >> "$logFile"		#Write final end time for entire task run
		if [ "${tNOTIFYSUCCESS,,}" = "true" ]; then				#If flag to notify upon command run success is enabled
			/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/notifier.sh --task "$tID" --status "SUCCESS" --log "$logFile" || true			#Call notification script, pass id+status+log path, error handling if notification fails
		fi
		exit 0			#Exit taskRunner.sh
	fi

	if [ $attemptNo -le "$tRETRIES" ]; then		#If max retries hasn't been reached
    	echo "Retrying after $tRETRYDELAY seconds:" >> "$logFile"			#Logs waiting and retry, including delay length
    	sleep "$tRETRYDELAY"			#Pause script for tRETRYDELAY seconds
	else
		echo "Max retries reached. Exit code: $exitCode" >> "$logFile"			#All allowed attemptes used, log final exit code
		echo "END_TIME=$(date --iso-8601=seconds)" >> "$logFile"			#Log final end time
		if [ "${tNOTIFYFAILURE,,}" = "true" ]; then				#If notifying upon failure allowed
			/mnt/c/Users/Nabhi/Downloads/SystemsFinalProject/bin/notifier.sh --task "$tID" --status "FAILURE" --log "$logFile" || true		#Log info similar to above
		fi
		exit $exitCode			#Exit taskRunner.sh w/ final exit code
	fi
done