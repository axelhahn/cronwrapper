
# Cronstatus

By starting the helper script 

```bash
/usr/local/bin/cronstatus.sh
```

it loops over all logfiles to see the last status of all your jobs (that were executed with the cronwrapper).

It shows the last execution time, the returncode and if the job is out of date.

In this example I have 2 cronjobs using the cronwrapper and both are OK. In that case the exit status is 0.

```text
> cronstatus.sh 

--- /var/tmp/cronlogs/www.example.com_scheduler.sh.log
    /opt/imlbackup/client/scheduler.sh
    last start: 2022-01-12 11:45:01, 1641984301
    returncode: 0 OK
    duration: 0 s
    ttl: 5 min OK
    expires: 1641985021 2022-01-12 11:57:01 OK

--- /var/tmp/cronlogs/www.example.com_imlpgcleanup.log
    /opt/imlpgcleanup/walarchivecleanup.sh -p /tmp -a 10
    last start: 2022-01-12 04:12:01, 1641957121
    returncode: 0 OK
    duration: 0 s
    ttl: 1440 - 24 h OK
    expires: 1642047121 2022-01-13 05:12:01 OK
    
> echo $?
0
```

The exit status of the cronstatus is always zero.
