#!/bin/bash
# see: https://phrye.com/code/periodic-monitoring/
# Example how to call this script:
# bash crontab-monitor.sh test /hd/server/cron/test.sh

start=$(date +%s)
# probably unused
textfile_dir=$(dirname "$0")
# name of the job
job="$1"
# path to script
script="$2"

PROMETHEUS_FILE="/hd/prometheus/node-textfile-metrics/cron_${job}.prom"

if [[ -z "$job" || -z "$script" ]]; then
  msg="ERROR: Missing arguments."
  exit_code=1
else 
	# Run the script.
	if [[ ! -x "$script" || -d "$script" ]]; then
		msg="ERROR: Can't find script for '$job'. Aborting."
		exit_code=2
	else 
		msg=$(bash "$script" 2>&1 >/dev/null )
		# Get results and clean up.
		exit_code=${PIPESTATUS[0]}
	fi
fi
finish=$(date +%s)
duration=$(( finish - start ))

#echo "job: $job"
#echo "exit code: $exit_code"
#echo "duration: $duration"
#echo "msg: $msg"
#exit 0

output="
# HELP cron_exitcode Exit code of runner.
# TYPE cron_exitcode gauge
cron_exitcode{script=\"$job\"} $exit_code
# HELP cron_finish Time latest run finished.
# TYPE cron_finish gauge
cron_finish{script=\"$job\"} $finish
# HELP cron_duration Duration of latest run.
# TYPE cron_duration gauge
cron_duration{script=\"$job\"} $duration
"
if [[ "$exit_code" -ne "0" ]]; then
	output+="
# HELP cron_message Always = exit_code, but provides a message as data if exit_code!=0
# TYPE cron_message gauge
cron_message{script=\"$job\", msg=\"$msg\"} $exit_code
"
fi

echo "$output" | sponge "$PROMETHEUS_FILE"
