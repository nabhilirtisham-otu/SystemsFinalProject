#Helper script used by sampleBad.sh leting it fail once and succeed the second time (used for testing purposes)

flagFile = "/mnt/c/Users/Nabhi/SystemsFinalProject/examples/sampleBadHelper.flag"
if [ ! -f "$flagFile" ]; then
	echo "First run fails intentionally"
	mkdir -p "$(dirname "$flagFile")"
	touch $flagfile
	exit 1
else
	echo "Second run succeeds"
	exit 0
fi