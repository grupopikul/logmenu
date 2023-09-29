#!/bin/bash

## Could take in argument like -g REGEX

function bfk {
	TMPFILE=$(mktemp)
	journalctl -kxb $1 -p $2 | ccze -A > $TMPFILE
	journalctl -kxfp 3 -n 0 | ccze -A >> $TMPFILE &
	TAIL_PID=$!
	less -RXS +F $TMPFILE
	kill $TAIL_PID 2> /dev/null
	rm $TMPFILE
}


function sel {
	export SYSTEMD_PAGER='less -RSXM'
	case $1 in
		1) bfk 0 3; menu;;
		2) bfk 0 4..4; menu;;
		3) bfk 0 7; menu;;
		4) bfk -1 7;  menu;;
	esac
}

function menu {
	echo ""
	uptime --pretty
	echo ""
	echo -n "NYC: "
	TZ='America/New_York' date +"%a %b %e %Y, %I:%M%P"
	echo -n "BOG: "
	TZ='America/Bogota' date +"%a %b %e %Y, %I:%M%P"
	echo -n "UTC: "
	date --utc +"%a %b %e %Y, %I:%M%P"
	echo ""
	echo -ne "1) Kernel Errors Since Boot:\t"
	journalctl -lkb -p 3 | wc -l
	echo -ne "2) Kernel Warnings Since Boot:\t"
	journalctl -lkb -p 4..4 | wc -l
	echo -ne "3) Kernel Entries Since Boot:\t"
	journalctl -lkb | wc -l
	echo -ne "   Kernel Errors Last Hour:\t"
	journalctl -lk -S "-1h" -p 3 | wc -l
	echo -ne "   Kernel Warnings Last Hour:\t"
	journalctl -lk -S "-1h" -p 4..4 | wc -l
	echo -ne "   Kernel Entries Last Hour:\t"
	journalctl -lk -S "-1h" | wc -l
	echo    "4) Kernel Everything Previous Boot"
	echo -n "Select: "
	read a
	sel $a
}


if [ -z "$1" ]; then
	menu
fi

# Now Look at System D Logs - Are systemd actions different than actual application output (like how do I record status changes)
# Print 
