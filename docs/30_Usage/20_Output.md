# Logged data

Have look into the directory after your first job was run.

```bash
/var/tmp/cronlogs/
```

The wrapper stores 3 information in different files

* The output of the last execution of a job
* a flagfile with a timestamp in it (0 byte)
* a daily log file with all executions of all jobs and their returncodes

The filenames contain the hostname (taken from `hostname -f`) and the label of the job (which is generated or given as 3rd param).

## Logfile

### Output

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

### Syntax

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

### Variables

To detect outdated jobs see section for cronstatus.sh on the next page.

| value           | type     | description |
|---              |---       |---          |
| SCRIPTNAME      | string   |  commandline of executed job; The value is taken from 1st parameter of cronwrapper commandline |
| SCRIPTTTL       | integer  | TTL value: in how many minutes this cronjob wust be repeated? The value is taken from 2nd parameter of cronwrapper commandline |
| SCRIPTSTARTTIME | datetime | starting time of the cronjob as time and (after comma) as unix timestamp; eg. `2022-09-22 09:48:58, 1663832938`|
| SCRIPTLABEL     | string   | label that will be part of the flag file and the log file name in the output directory. By default it is generated but you can override it with a 3rd parameter in cronwrapper commandline |
| SCRIPTPROCESS   | integer  | process id |
| JOBEXPIRE       | integer  | Unix timestamp when the job is expired. t is calculated by starttime plus TTL |
| SCRIPTENDTIME   | datetime | ending time of the cronjob as time and (after comma) as unix timestamp; eg. `2022-09-22 09:48:12, 1663832938`|
| SCRIPTEXECTIME  | string   | Needed time for execution in seconds as human readable time; the delta of endtime - starttime |
| SCRIPTRC        | integer  | returncode of the executed commandline |
| SCRIPTOUT       | string   | Output of the executed command. This value can be repeated in the log on multiline outputs

## flagfile

The flagfile is a zero byte file with a generated filename from label, expiration time and hostname.
The label correspondents to a log file.

The flagfile will be touched if a cronjob was finished.

## joblog

The daily joblog exists for jobs that run several / many times per day. It stores the Label of a job, the starting time and a result code.

You have the results and exectime for all started jobs of the last 6 weekdays in the log diectory. The log of the 7th day automatically will be removed.

```txt
axel@linux-pc /v/t/cronlogs> pwd
/var/tmp/cronlogs

axel@linux-pc /v/t/cronlogs> ls -1 *joblog*
linux-pc_joblog_Fri.done*
linux-pc_joblog_Sat.done*
linux-pc_joblog_Sun.done*
linux-pc_joblog_Thu.done*
linux-pc_joblog_Tue.done*
linux-pc_joblog_Wed.done*
```

Let's have look to it:

```txt
axel@linux-pc /v/t/cronlogs> head -3 linux-pc_joblog_Sun.done
job=restic-backup:host=linux-pc:start=1689458821:end=1689458905:exectime=84:ttl=60:rc=0
job=restic-backup:host=linux-pc:start=1689502021:end=1689502113:exectime=92:ttl=60:rc=0
job=restic-backup:host=linux-pc:start=1689505621:end=1689505708:exectime=87:ttl=60:rc=0
```

With a delimter `:` you see these data (values like in the job logs)

* job - label of the job
* host - hostname 
* start - starttime as unix timestamp
* end - endtime as unix timestamp
* exectime - execution time of the job in sec
* ttl - the ttl value
* rc - return code
* blockedbypid - optional: when using option SINGLEJOB=1 and a 2nd job will be executed you get the pid that blocked its execution.
