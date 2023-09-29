# logmenu
A simple interface to the important logs


## New Roadmap

So now we have to look at systemd logs
0. Uptime
1. If it makes sense, put it in follow (kernel, follow with history)
2. What do the unit files say about restarts and stuff
3. Systemd (display all general items)
4. Status of units of interes, stats:
* Number of Reboots?
* Number of Errors?
* Number of Warnings?
* How long as it been up?
5. Logs for items of interest (Last Boot? Just End)


## Roadmap
**First Look at other options**
* read json file or other file to print out menu options
* easy access to systemd/journald log files of import with relevant options (priority, boot, kernel, since)  
_this is really why we need this, because besides learning journald commands, i don't want to re-remember which priorities are relevant for every application. For example, `sshd` prints out a ton of errors for every connection. Really not necessary to report client errors, but here we are._
* always follow with some history
* allow asking for minutes or hours back
* pipe it into some kind of pretty processor.
* give it a decent date printer with timezon
