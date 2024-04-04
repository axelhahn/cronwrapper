## Cronstatus

### Show help

By starting the helper script 

```txt
> cronstatus.sh -h
______________________________________________________________________________


  AXELS CRONWRAPPER
  Jobstatus of cronjobs on 🖥 linux-pc
                                                                         v 2.1
______________________________________________________________________________


Show the status of all local cronjobs that use the cronwrapper or a single job
by giving its logfile as parameter.

This script is part of Axels Cronwrapper.
  📜 License: GNU GPL 3.0
  📗 Docs   : https://www.axel-hahn.de/docs/cronwrapper/


####| ✨ SYNTAX |####

  cronstatus.sh [OPTIONS] [LOGFILE|LABEL]


####| 🔧 OPTIONS |####

  -h|--help        show this help and exit.

  -d|--nodetails   hide detailed meta infos
  -i|--nointro     hide starting header
  -l|--nolast      hide last executions
  -o|--nooutput    hide logfile output (when adding a param for logfile|label)
  -r|--norunning   hide running processes
  -s|--short       short status; sortcut for '-d -i -l -r'


####| 🏷 PARAMETERS |####

  LOGFILE  filename to show details of a single logfile
  LABEL    label of a job

  Default: without any logfile/ label you get a total overview of all
           cronjobs.


####| 🧩 EXAMPLES |####

  cronstatus.sh
           show total overview over all jobs

  cronstatus.sh -s
           Show tiny status for all jobs without intro header or details

  cronstatus.sh myjob
           show output of a single job

  cronstatus.sh /var/tmp/cronlogs/myjobfile.log
           show output of a single job

```

### Execute without parameter

It loops over all logfiles to see the last status of all your jobs (that were executed with the cronwrapper).

It shows the last execution time, the returncode and if the job is out of date.

In case of an error it returns the last lines of output.

It verifys the hostname with that one parsed from the log.

In this example I have 2 cronjobs using the cronwrapper and both are OK. In that case the exit status is 0.

```text
> cronstatus.sh 
______________________________________________________________________________


  AXELS CRONWRAPPER
  Jobstatus of cronjobs on 🖥 linux-pc
                                                                         v 2.0
______________________________________________________________________________
..... ✔ OK: restic-backup

    Command   : /home/axel/skripte/iml-backup/backup.sh
    Last start: 2024-04-01 21:07:00, 1711998420
    Returncode: 0 OK
    Duration  : 241 s
    Ttl       : 60 min OK
    Expires   : 1712005620 2024-04-01 23:07:00 OK

    Logfile   : /var/tmp/cronlogs/linux-pc_restic-backup.log

    Last executions:

        Result      Start time             rc    Execution time
        ---------   -------------------   ---   ---------------
        OK         2024-04-01 21:07:00     0            241 s
        OK         2024-04-01 20:07:00     0            141 s
        OK         2024-04-01 19:07:00     0            119 s
        OK         2024-04-01 18:07:00     0            127 s
        OK         2024-04-01 17:07:00     0            203 s
        OK         2024-04-01 16:07:00     0            120 s
        OK         2024-04-01 15:07:00     0            197 s
        OK         2024-04-01 14:07:00     0            179 s
        OK         2024-04-01 01:07:00     0            112 s
        OK         2024-04-01 00:07:00     0            117 s

There is no running job.
____________________________________________________________________________________
JOBS: 1 .. RUNNING: 0 .. ERRORS: 0

```

If a job is currently running you get a shorter info block with the time how long it is running already.

```txt
(...)
____________________________________________________________________________________
CURRENTLY RUNNING JOBS:

    --- ⏳ for 2 min - /var/tmp/cronlogs/linux-pc_restic-backup.log.running.NNNNN
        command   : /home/axel/skripte/client/backup.sh
        last start: 2024-06-01 22:07:01, ...
        ttl       : 60
        OK - still running
(...)
```

If the job was aborted - maybe because of a reboot while the job was running) you get a line `ERROR: The process NNNNN does not exist anymore.` 
Then you should check the file content and delete it, eg by using `./cronstatus.sh [logfile]` (see below)

#### Exitcode

The exit status of the cronstatus is the count of found jobs with error.
It is zero if all jobs are OK.

```txt
> echo $?
0
```

You can execute this script in a monitoring check, to get a warning about a failed or expired cronjob.

Example for Icinga2:

https://git-repo.iml.unibe.ch/iml-open-source/icinga-checks/-/blob/master/check_cronstatus


#### Example output on error

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

### View detail

If you add a logfile as parameter you get a highlighted output of the log and the analysis section for this job.

```txt
./cronstatus.sh [logfile|label]
```

In this example I executed a dummy cronjob: `ls` with a ttl of 10 min. This shows detail view shos

* OK for the exitcode 0
* ERROR for the expired job (log is now older than 10 min)

![Screenshot: detail view of a single logfile](/images/cronstatus_detail.png)