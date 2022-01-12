
Have look into the directory after your first job was run.
```bash
/var/tmp/cronlogs/
```

The wrapper stores 3 information in different files

* The output of the last execution of a job
* a flagfile with a timestamp in it (0 byte)
* a daily log file with all executions of all jobs and thheir returncodes

### logfile

Show the created output of a cronjob:
```bash
cat /var/tmp/cronlogs/[your-logfile]*.log
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
To detect outdated jobs see section for cronstatus.sh below.

### joblog

The daily joblog exists for jobs that run several /  many times per day. It stores the Label of a job, the starting time and a result code.
