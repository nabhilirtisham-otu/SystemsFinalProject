# This script executes a task - includes timeout, retrying, and logging functionality

set -euo pipefail

# Load the configuration file defined in configs/default.conf
SELFDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="/mnt/c/Users/Nabhi/SystemsFinalProject/configs/default.conf"
if [ -f "$CONFIG" ]; then
	source "$CONFIG"
fi

