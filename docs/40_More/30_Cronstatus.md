
# Cronstatus

## Show help

By starting the helper script 

```txt
> cronstatus.sh -h
____________________________________________________________________________________

CRONJOBS on [linux-pc]
______________________________________________________________________________/ v1.9

SYNTAX: cronstatus.sh [OPTIONS|LOGFILE]

OPTIONS:
    -h       show this help and exit.

PARAMETERS:
    LOGFILE  filename or label to show details of a single logfile
             Default: without any logfile you get a total overview of all 
             cronjobs.
EXAMPLES:
    cronstatus.sh
             show total overview over all jobs

    cronstatus.sh /var/tmp/cronlogs/myjobfile.log
             show output of a single job

```

## Execute without parameter

It loops over all logfiles to see the last status of all your jobs (that were executed with the cronwrapper).

It shows the last execution time, the returncode and if the job is out of date.

In case of an error it returns the last lines of output.

It verifys the hostname with that one parsed from the log.

In this example I have 2 cronjobs using the cronwrapper and both are OK. In that case the exit status is 0.

```text
> cronstatus.sh 
____________________________________________________________________________________

CRONJOBS on [www.example.com]
______________________________________________________________________________/ v1.7

--- /var/tmp/cronlogs/www.example.com_scheduler.sh.log
    command   : /opt/imlbackup/client/scheduler.sh
    last start: 2022-01-12 11:45:01, 1641984301
    returncode: 0 OK
    duration  : 0 s
    ttl       : 5 min OK
    expires   : 1641985021 2022-01-12 11:57:01 OK
    CHECK OK

--- /var/tmp/cronlogs/www.example.com_imlpgcleanup.log
    command   : /opt/imlpgcleanup/walarchivecleanup.sh -p /tmp -a 10
    last start: 2022-01-12 04:12:01, 1641957121
    returncode: 0 OK
    duration  : 0 s
    ttl       : 1440 - 24 h OK
    expires   : 1642047121 2022-01-13 05:12:01 OK
    CHECK OK

There is no running job.
____________________________________________________________________________________
JOBS: 1 .. RUNNING: 1 .. ERRORS: 0

```

If a job is currently running you get a shorter info block with the time how long it is running already.

```txt
(...)
____________________________________________________________________________________
CURRENTLY RUNNING JOBS:

    --- for 2 min - /var/tmp/cronlogs/my-laptop_iml-backup.log.running.NNNNN
        command   : /home/axel/skripte/client/backup.sh
        last start: 2023-05-22 13:44:40, 1684755880
        ttl       : 1440
        OK - still running
(...)
```

If the job was aborted - maybe because of a reboot while the job was running) you get a line `ERROR: The process NNNNN does not exist anymore.` 
Then you should check the file content and delete it, eg by using `./cronstatus.sh [logfile]` (see below)

### Exitcode

The exit status of the cronstatus is the count of found jobs with error.
It is zero if all jobs are OK.

```txt
> echo $?
0
```

You can execute this script in a monitoring check, to get a warning about a failed or expired cronjob.

Example for Icinga2:

https://git-repo.iml.unibe.ch/iml-open-source/icinga-checks/-/blob/master/check_cronstatus


### Example output on error

On Error you get the last lines of the output with tail command.
It is a try to help - if the log is a bit bigger you need to open the log.

```txt
--- /var/tmp/cronlogs/www.example.com_testjob2.log
    command   : ls /some-non-existing
    last start: 2022-09-22 10:00:28, 1663833628
    returncode: 2 ERROR

        Last lines in output:
        ls: cannot access '/some-non-existing': No such file or directory

    duration  : 0 s
    ttl       : 30 min OK
    expires   : 1663838128 2022-09-22 11:15:28 OK
    CHECK FAILED
```

## View detail

If you add a logfile as parameter you get a highlighted output of the log and the analysis section for this job.

```txt
./cronstatus.sh [logfile|label]
```

In this example I executed a dummy cronjob: `ls` with a ttl of 10 min. This shows detail view shos

* OK for the exitcode 0
* ERROR for the expired job (log is now older than 10 min)

![Screenshot: detail view of a single logfile](/images/cronstatus_detail.png)