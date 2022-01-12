# Help

Use -h to show a help:

```text
cronwrapper.sh -h

--------------------------------------------------------------------------------

AXELS CRONWRAPPER
Puts control and comfort to cronjobs.

source: https://github.com/axelhahn/cronwrapper
license: GNU GPL 3.0

--------------------------------------------------------------------------------

Showing help ...


SYNTAX: ./cronwrapper.sh TTL COMMAND [LABEL]

PARAMETERS:
    TTL       integer value in [min]
              This value how often your cronjob runs. It is used to verify
              if a cronjob is out of date / does not run anymore.

    COMMAND   command to execute
              When using spaces or parameters then quote it.
              Be strict: if your job is ok then exit wit returncode 0.
              If an error occurs exit with returncode <> 0.

    LABEL     optional: label to be used as output filename
              If not set it will be detected from basename of executed command.
              When you start a script with different parameters it is highly
              recommended to set the label.

REMARK:
You don't need to redirect the output in a cron config file. STDOUT and
STDERR will be fetched automaticly. 
It also means: Generate as much output as you want and want to have to debug a
job in error cases.

OUTPUT:
The output directory of all jobs executed by ./cronwrapper.sh is
/var/tmp/cronlogs.
The output logs are parseble with simple grep command.

MONITORING:
You can run ./cronstatus.sh to get a list of all cronjobs and its
status. Check its source. Based on its logic you can create a check script for
your server monitoring.
```

# Replace existing Cronjobs

As an example ... if you have a daily cronjob like this starting at 3:12 am:

```bash
12 3 * * * root /usr/local/bin/my-database-dumper.sh >/tmp/dump.log 2>&1
```

To use my wrappper

* you add the wrapper in front
* add a TTL (in minutes) as first param. It defines how often this job is called. This will let us detect if a job is out of date.
* add the command as third param - if you use arguments, then you need to quote it
* optional: add a label for the output file (it overrides the default naming convention of the log)
* remove the output redirections

The cronjob above needs to be rewritten like that:

```bash
12 3 * * * root /usr/local/bin/cronwrapper.sh 1440 /usr/local/bin/my-database-dumper.sh
```

To test it immediately run con command line:

```bash
/usr/local/bin/cronwrapper.sh 1440 /usr/local/bin/my-database-dumper.sh
```

You may ask: And what is the difference now?
First: your task does the same thing(s) like before.

But what the additional wrapper does:

* The wrapper fetches any output of stdout + stderr and creates a log file with a name based on the started script 
  (remark: you can override the naming with a 3rd parameter).
  Do not try to keep silent anymore: write as many output as you want! Write the output that you can understand the execution!
* The wrapper logs  a few things by itself: 
  * the started command
  * starting time
  * ending time
  * ... and if having them: the execution time
  * the exitcode of the command/ script;
    This means: be strinct like all commands do! Write your cronjob script that
    ends with exitcode 0 if it is successful and quit with non-zero if any
    error occurs. Be strict!
  * The TTL value (parameter 2) generates a file with a timestamp. The check
    script detects with it if a cronjob log is outdated
* all metadata and the output will be written in a log file with parsable
syntax! That's the key. Just using grep and cut you could verify all your jobs. But there is
an additional check script too: run cronstatus.sh
