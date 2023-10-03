#!/bin/bash

## Could take in argument like -g REGEX
## Do we need dmesg?
function touch_date {
	if [ -n "$CONFIG_DIR" ]; then
		date +"%Y-%m-%d %H:%M:%S" > $CONFIG_DIR/date
		last_check="$(cat $CONFIG_DIR/date)"
	else
		echo "Can't do that unless you specify a configuration directory"
		read p
	fi
}

if [ -d "$1" ]; then
	CONFIG_DIR=$1
	if [ -f "$CONFIG_DIR/date" ]; then
		last_check="$(cat $CONFIG_DIR/date)"
		date +"%Y-%m-%d %H:%M:%S" -d "${last_check}" &> /dev/null || last_check=""
	else
		touch "$CONFIG_DIR/date"
	fi
else
	echo "Warning: no configuration directory"
	CONFIG_DIR=""
fi

if [ -z "$last_check" ]; then
	last_check="$(uptime -s)"
fi

function bfk {
	TMPFILE=$(mktemp)
	journalctl -kb $1 -p $2 | ccze -A > $TMPFILE
	while read -r line; do
		echo "$line" | ccze -A >> $TMPFILE
	done < <(journalctl -kfp $2 -n 0) &
	TAIL_PID=$!
	less -RXS +F $TMPFILE
	kill $TAIL_PID 2> /dev/null
	rm $TMPFILE
}

function bfuser {
	TMPFILE=$(mktemp)
	journalctl -n 5000 --user-unit=$1 | ccze -A > $TMPFILE
	while read -r line; do
		echo "$line" | ccze -A >> $TMPFILE
	done < <(journalctl  --user-unit=$1 -f -n 0) &
	TAIL_PID=$!
	less -RXS +F $TMPFILE
	kill $TAIL_PID 2> /dev/null
	rm $TMPFILE
}

function bfsys {
	TMPFILE=$(mktemp)
	journalctl -n 5000 --unit=$1 | ccze -A > $TMPFILE
	while read -r line; do
		echo "$line" | ccze -A >> $TMPFILE
	done < <(journalctl --unit=$1 -f -n 0) &
	TAIL_PID=$!
	less -RXS +F $TMPFILE
	kill $TAIL_PID 2> /dev/null
	rm $TMPFILE
}

declare -A usermap
declare -A sysmap
function sel {
	if [[ -n "${usermap[$1]}" ]]; then
		bfuser $1
	fi
	if [[ -n "${sysmap[$1]}" ]]; then
		bfsys $1
	fi
	case $1 in
		"") menu;;
		0) touch_date; menu;; 
		1) bfk 0 3; menu;;
		2) bfk 0 4..4; menu;;
		3) bfk 0 7; menu;;
		4) bfk -1 7;  menu;;
		q) exit 0
	esac
	echo "**Unknown Command: $1**"
	menu
}

function columnize {
	# Errors Since Check
	esc=$(journalctl -qlb -S "$last_check" -p 3 $2$1 | wc -l)
	# Errors Last Hour
	esh=$(journalctl -ql -S "-1h" -p 3 $2$1 | wc -l)
	# Errors Last 2 Min
	es2=$(journalctl -ql -S "-2min" -p 3 $2$1 | wc -l)
	# Warnings Since Check
	wsc=$(journalctl -qlb -S "$last_check" -p 4..4 $2$1 | wc -l)
	# Warnings Last Hour
	wsh=$(journalctl -ql -S "-1h" -p 4..4 $2$1 | wc -l)
	# Warnings Last 2 Min
	ws2=$(journalctl -ql -S "-2min" -p 4..4 $2$1 | wc -l)
	# Entries Since Check
	asc=$(journalctl -qlb -S "$last_check" $2$1 | wc -l)
	# Entries Last Hour
	ash=$(journalctl -ql -S "-1h" $2$1 | wc -l)
	# Entries Last 2 Min
	as2=$(journalctl -ql -S "-2min" $2$1 | wc -l)
	distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(60*60*24) )) # days
	postfix=" days"
	if [ "$distance" == "0" ]; then
		distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(60*60) )) # hours
		postfix=" hours"
		if [ "$distance" == "0" ]; then
			distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(60) )) # minutes
			postfix=" minutes"
			if [ "$distance" == "0" ]; then
			distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(1) )) # seconds
			postfix=" seconds"
			fi
		fi
	fi
	echo -e "--${distance}${postfix}--hour--2min\nerrors--$esc--$esh--$es2\nwarning--$wsc--$wsh--$ws2\nall--$asc--$ash--$as2" | column -t -s '--'
}

function menu {
	clear
	echo "*********************************************"
	echo -n "LOC: "
	date +"%a %b %e %Y, %I:%M%P"
	echo -n "NYC: "
	TZ='America/New_York' date +"%a %b %e %Y, %I:%M%P"
	echo -n "BOG: "
	TZ='America/Bogota' date +"%a %b %e %Y, %I:%M%P"
	echo -n "UTC: "
	date --utc +"%a %b %e %Y, %I:%M%P"
	echo ""
	uptime --pretty
	failed_units="$(systemctl list-units --failed -q)"
	if [ -n "$failed_units" ]; then
		systemctl list-units --failed -q
	else
		echo "No failed units"
	fi
	echo ""


	# Kernel Errors Since Boot
	esb=$(journalctl -qlkb -p 3 | wc -l)
	# Kernel Errors Since Check
	esc=$(journalctl -qlkb -S "$last_check" -p 3 | wc -l)
	# Kernel Errors Last Hour
	esh=$(journalctl -qlk -S "-1h" -p 3 | wc -l)
	# Kernel Errors Last 2 Min
	es2=$(journalctl -qlk -S "-2min" -p 3 | wc -l)
	# Kernel Warnings Since Boot
	wsb=$(journalctl -qlkb -p 4..4 | wc -l)
	# Kernel Warnings Since Check
	wsc=$(journalctl -qlkb -S "$last_check" -p 4..4 | wc -l)
	# Kernel Warnings Last Hour
	wsh=$(journalctl -qlk -S "-1h" -p 4..4 | wc -l)
	# Kernel Warnings Last 2 Min
	ws2=$(journalctl -qlk -S "-2min" -p 4..4 | wc -l)
	# Kernel Entries Since Boot
	asb=$(journalctl -qlkb | wc -l)
	# Kernel Entries Since Check
	asc=$(journalctl -qlkb -S "$last_check" | wc -l)
	# Kernel Entries Last Hour
	ash=$(journalctl -qlk -S "-1h" | wc -l)
	# Kernel Entries Last 2 Min
	as2=$(journalctl -qlk -S "-2min" | wc -l)
	distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(60*60*24) )) # days
	postfix=" days"
	if [ "$distance" == "0" ]; then
		distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(60*60) )) # hours
		postfix=" hours"
		if [ "$distance" == "0" ]; then
			distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(60) )) # minutes
			postfix=" minutes"
			if [ "$distance" == "0" ]; then
			distance=$(( ($(date +%s) - $(date --date="$last_check" +%s) )/(1) )) # seconds
			postfix=" seconds"
			fi
		fi
	fi
	
	echo "Kernel:"
	echo -e "--boot--${distance}${postfix}--hour--2min\nerrors--$esb--$esc--$esh--$es2\nwarning--$wsb--$wsc--$wsh--$ws2\nall--$asb--$asc--$ash--$as2" | column -t -s '--'
	
	my_systemd=$(ps -u -x | grep "systemd --user" | grep -v grep | awk '{print $2}') # this can be used to print out specific systemd info
	# we can use _PID= w/ 1 and $my_systemd to see what's been going on with just systemD
	if [ -f "$CONFIG_DIR/user" ]; then
		while IFS="" read -r unit || [ -n "$unit" ]; do
			usermap[$unit]="true"
			echo "************"
			IFS=';' read -r service loaded active alive name < <(systemctl --user --all | grep $unit | xargs | sed -e 's/ /---/g5' | sed -e 's/ /;/g' | sed -e 's/---/ /g')
			since=""
			exitstatus=""
			color=""
			nocolor=""
			if [ "$alive" = "dead" ]; then
				since="since $(systemctl --user status $unit | grep 'Active: inactive (dead)' | sed -n 's/^.*;//p')"
				exitstatus="with $(systemctl --user status $unit | grep status= | head -n 1 | sed -n 's/^.*status=//p' | sed -n 's/)//p')"
				color="\e[31m"
				nocolor="\e[0m"
			fi
			echo -e $color$name, $service: $alive $since $exitstatus$nocolor
			columnize $unit --user-unit=
		done<$CONFIG_DIR/user
	fi

	if [ -f "$CONFIG_DIR/sys" ]; then
		while IFS="" read -r unit || [ -n "$unit" ]; do
			sysmap[$unit]="true"
			echo "************"
			IFS=';' read -r service loaded active alive name < <(systemctl --all | grep $unit | xargs | sed -e 's/ /---/g5' | sed -e 's/ /;/g' | sed -e 's/---/ /g')
			since=""
			exitstatus=""
			color=""
			nocolor=""
			if [ "$alive" = "dead" ]; then
				since="since $(systemctl status $unit | grep 'Active: inactive (dead)' | sed -n 's/^.*;//p')"
				exitstatus="with $(systemctl status $unit | grep status= | head -n 1 | sed -n 's/^.*status=//p' | sed -n 's/)//p')"
				color="\e[31m"
				nocolor="\e[0m"
			fi
			echo -e $color$name, $service: $alive $since $exitstatus$nocolor
			columnize $unit --unit=
		done <$CONFIG_DIR/sys
	fi
	
	# go through each one, printing out quantities in the same way as kernel for each service i'm interested in
	# first, we need a list of units relevant- that can just be reading a file line by line, user units, system units
	# this would probably be good accounting anyway
	# we need ideas about what to grep, and to see full logs... probably as good of a time as any to get a column
	# #
	# #
	# #
	# #
	# #
	# It should follow the column above
	# And we should let them also see full logs for all those services
	# Then we should look at unit specific logs - error, warning, entry
	# but can we do since last restart
	#

	echo ""
	echo "Select:"
	echo "Enter to reprint"
	echo "0) Add Check Date"
	echo "1) Kernel Errors Since Boot"
	echo "2) Kernel Warnings Since Boot"
	echo "3) Kernel Entries Since Boot"
	echo "4) Kernel Everything Previous Boot"
	echo "Or type a full unit name"
	## Add Default Here

	echo ""
	echo -n "Select: "
	read a
	sel $a
}


menu

# Now Look at System D Logs - Are systemd actions different than actual application output (like how do I record status changes)
# Print 
