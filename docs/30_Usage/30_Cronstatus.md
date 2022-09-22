
# Cronstatus

## Execute

By starting the helper script 

```bash
/usr/local/bin/cronstatus.sh
```

It does not support parameters.

It loops over all logfiles to see the last status of all your jobs (that were executed with the cronwrapper).

It shows the last execution time, the returncode and if the job is out of date.

## Output

In this example I have 2 cronjobs using the cronwrapper and both are OK. In that case the exit status is 0.

```text
> cronstatus.sh 
____________________________________________________________________________________

CRONJOBS on [www.example.com]
______________________________________________________________________________/ v1.4

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
____________________________________________________________________________________
JOBS: 2 .. ERRORS: 0

```

## Exitcode

The exit status of the cronstatus is the count of found jobs with error.
It is zero if all jobs are OK.

```txt
> echo $?
0
```

## Example output on error

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