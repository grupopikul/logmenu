#!/bin/bash

## Could take in argument like -g REGEX
# Could also use -x is useful
function sel {
	case $1 in
		1) journalctl -ekb -p 3; menu ;;
		2) journalctl -ekb -p 4..4; menu;;
		3) journalctl -ekb; menu;;
		4) journalctl -ek -p 3; menu;;
		5) journalctl -ek -p 4..4; menu;;
		6) journalctl -ek; menu;;
		7) journalctl -ekb -1; menu ;;
	esac
}

function menu {
	echo -n "NYC: "
	TZ='America/New_York' date +"%a %b %e %Y, %I:%M%P"
	echo -n "BOG: "
	TZ='America/Bogota' date +"%a %b %e %Y, %I:%M%P"
	echo -n "UTC: "
	date --utc +"%a %b %e %Y, %I:%M%P"
	echo ""
	echo -n "1) Kernel Errors Since Boot: "
	journalctl -lkb -p 3 | wc -l
	echo -n "2) Kernel Warnings Since Boot: "
	journalctl -lkb -p 4..4 | wc -l
	echo -n "3) Kernel Entries Since Boot: "
	journalctl -lkb | wc -l
	echo -n "4) Kernel Errors Last Hour: "
	journalctl -lk -S "-1h" -p 3 | wc -l
	echo -n "5) Kernel Warnings Last Hour: "
	journalctl -lk -S "-1h" -p 4..4 | wc -l
	echo -n "6) Kernel Entries Last Hour: "
	journalctl -lk -S "-1h" | wc -l
	echo    "7) Kernel Everything Previous Boot"
	echo -n "Select: "
	read a
	sel $a
}


if [ -z "$1" ]; then
	menu
fi

# Now Look at System D Logs - Are systemd actions different than actual application output (like how do I record status changes)
# Print 
