# logmenu
A simple interface to the important logs

## Roadmap
**First Look at other options**
* read json file or other file to print out menu options
* easy access to systemd/journald log files of import with relevant options (priority, boot, kernel, since)  
_this is really why we need this, because besides learning journald commands, i don't want to re-remember which priorities are relevant for every application. For example, `sshd` prints out a ton of errors for every connection. Really not necessary to report client errors, but here we are._
* always follow with some history
* allow asking for minutes or hours back
* pipe it into some kind of pretty processor.
* give it a decent date printer with timezon
