# monitor_cronjob_prometheus
Monitor your cronjobs with (in order): wrapper script, node_exporter, prometheus, grafana. This repository provides an implementation of the wrapper script I created.

# How to use

Save this script on your server.
Instead of directly executing scripts in crontab use this as wrapper script.

e.g. instead of:

	0 * * * * bash /hd/ddnss-update.sh
	
use:

	0 * * * * bash /hd/crontab-monitor.sh ddnss-update /hd/ddnss-update.sh
	
The arguments are:
(1) name you want to give the cronjob in your monitoring (above "ddnss-update")
(2) path to the script to execute. (above "/hd/ddnss-update.sh")

NOTE: As of now this wrapper script does not support any arguments. You can easily put the arguments inside the script you are calling instead.


## Prometheus metrics file

The wrapper script places a metrics file inside your desired directory.
You should probably configure the path for your setup.
See the variable PROMETHEUS_FILE inside the crontab-monitor.sh script.

An example how the output (cron_ddnss-update.prom) should look like:

	# HELP cron_exitcode Exit code of runner.
	# TYPE cron_exitcode gauge
	cron_exitcode{script="ddnss-update"} 0
	# HELP cron_finish Time latest run finished.
	# TYPE cron_finish gauge
	cron_finish{script="ddnss-update"} 1592146802
	# HELP cron_duration Duration of latest run.
	# TYPE cron_duration gauge
	cron_duration{script="ddnss-update"} 1

There are 3 metrics exported by the script.
Exitcode of your script, when it finished and the duration it took to execute it.

## Node_exporter

Configure your node_exporter to pick up on these custom generated prometheus metrics.

An example if you setup your node_exporter with docker-compose:

	version: '3.7'
	services:
		prometheus_node:
			container_name: prometheus-node
			restart: unless-stopped
			image: prom/node-exporter:v1.0.0-rc.0
			network_mode: "host"
			volumes:
				- /proc:/host/proc:ro
				- /sys:/host/sys:ro
				- /:/host/rootfs:ro
				- /hd/prometheus/node-textfile-metrics:/var/node-textfile-metrics:ro
			command: 
				- '--path.procfs=/host/proc'
				- '--path.sysfs=/host/sys'
				- '--path.rootfs=/host/rootfs'
				# note $ is escaped with another $ thus resulting in $$ below:
				- '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
				- '--collector.textfile.directory="/var/node-textfile-metrics"'
				- '--web.listen-address=:9101'
			depends_on:
				- prometheus
				
The important part is the additional argument "--collector.textfile.directory" 
where you specify the path to your prometheus metric files.
The file "cron_ddnss-update.prom" from the above example should be in this folder.

# references

To write the wrapper script I used this as reference:

	https://phrye.com/code/periodic-monitoring/