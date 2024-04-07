## Quickstart Guide

### Install

Git clone the repository in /opt

```shell
cd /opt
git clone https://github.com/axelhahn/cronwrapper.git
```

### First test run

Let's start a simple command like `ls`:<br> `/opt/cronwraper/cronwrapper.sh 1 ls` 

There was no output - because this is what we want in linux cronjobs.

* To see the status for all cronjobst start `/opt/cronwraper/cronstatus.sh`. 
* Details you see with `/opt/cronwraper/cronstatus.sh ls`
* Wait for 1..2 min and run `/opt/cronwraper/cronstatus.sh ls` again: Now you see that the execution was successful but the TTL was reached and shows an error. 

### Edit a cronjob

Edit a cronjob in `crontab -e` or as root a file in `/etc/cron.d/`:

* add "/opt/cronwrapper/cronwrapper.sh" and TTL in [min] before the existing command.
* The command must be a parameter - if it contains spaces to use parameters, you need to quote it
* remove the redirect to a file.
* Example:<br>![Rewrite an existing cronjob](images/rewrite_a_cronjob.drawio.png)
* Check `/opt/cronwraper/cronstatus.sh` after jor job was executed
