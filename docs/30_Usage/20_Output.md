# Logged data

Have look into the directory after your first job was run.

```bash
/var/tmp/cronlogs/
```

The wrapper stores 3 information in different files

* The output of the last execution of a job
* a flagfile with a timestamp in it (0 byte)
* a daily log file with all executions of all jobs and their returncodes

## logfile

Show the created output of a cronjob:

```bash
cat /var/tmp/cronlogs/[your-logfile]*.log

REM --------------------------------------------------------------------------------
REM CRON WRAPPER - www.example.com
REM --------------------------------------------------------------------------------
SCRIPTNAME=[Commandline of executed job]
SCRIPTTTL=30
SCRIPTSTARTTIME=2022-09-22 09:48:58, 1663832938
SCRIPTLABEL=testjob
SCRIPTPROCESS=32396
REM --------------------------------------------------------------------------------
REM OK, executing job the first time
JOBEXPIRE=1663837438
REM --------------------------------------------------------------------------------
SCRIPTENDTIME=2022-09-22 09:48:12, 1663832938
SCRIPTEXECTIME=14 s
SCRIPTRC=0
REM --------------------------------------------------------------------------------
SCRIPTOUT=[OUTPUT LINE 1]
SCRIPTOUT=[OUTPUT LINE 2]
SCRIPTOUT=...
SCRIPTOUT=[OUTPUT LINE N]
REM --------------------------------------------------------------------------------
REM /opt/cronwrapper/cronwrapper.sh finished at Do 22 Sep 2022 09:48:58 CEST
```

You see lines with

* REM - comment lines (to make the output file more readable)
* [VARIABLE] = [Output]

This simple syntax was chosen to use a normal grep command to scan for a specific information.

To search for a specific information, i.e. the return code (SCRIPTRC) of your script 

```bash
grep "^SCRIPTRC" /var/tmp/cronlogs/[your-logfile]*.log
```

... or all last execution resultcode of each job on the machine:

```bash
grep "^SCRIPTRC" /var/tmp/cronlogs/*.log
```

The last command tests the returncode only. 
To detect outdated jobs see section for cronstatus.sh on the next page.

## joblog

The daily joblog exists for jobs that run several /  many times per day. It stores the Label of a job, the starting time and a result code.
