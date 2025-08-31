## Introduction

The cronwrapper.sh is a script to wrap your (existing) cronjob. 

It does a few small and helpful things:

* The wrapper fetches any output of stdout + stderr and creates a log file with a name based on the started script 
  (remark: you can override the naming with a 3rd parameter).
  Do not try to keep silent anymore: write as many output as you want! 
  And some more good news: Write the output in your cronscripts that you can understand the execution!
* The wrapper logs a few things by itself: 
  * the started command
  * starting time
  * ending time
  * ... and if having them: the execution time
  * the exitcode of the command/ script;
    This means: be strict like all commands do! Write your cronjob script that
    ends with exitcode 0 if it is successful and quit with non-zero if any
    error occurs. Be strict with the exitcode to be able to monitor the cronjobs!
  * The TTL value (parameter 2) generates a file with a timestamp. A check
    script detects with it if a cronjob log is outdated
* all metadata and the output will be written in a log file with parsable

## Show help

Use -h to show a help:

```text
cronwrapper.sh -h
./cronwrapper.sh -h

                                                                           | 
    A  X  E  L  S                                                        --x--
   ______                        ________                                  |
  |      |.----.-----.-----.    |  |  |  |.----.---.-.-----.-----.-----.----.
  |   ---||   _|  _  |     |    |  |  |  ||   _|  _  |  _  |  _  |  -__|   _|
  |______||__| |_____|__|__|    |________||__| |___._|   __|   __|_____|__|  
                                                     |__|  |__|
                                                                       v 2.7


  Puts control and comfort to your cronjobs.

  📄 Source : https://github.com/axelhahn/cronwrapper
  📜 License: GNU GPL 3.0
  📗 Docs   : https://www.axel-hahn.de/docs/cronwrapper/


####| ✨ SYNTAX |####

  ./cronwrapper.sh TTL COMMAND [LABEL]


####| 🏷 PRAMETERS |####

  TTL     integer value in [min]
          This value says how often your cronjob runs. It is used to verify
          if a cronjob is out of date / does not run anymore.
          As a fast help a few values:
            60    - 1 hour
            1440  - 1 day
            10080 - 7 days
  
  COMMAND command to execute
          When using spaces or parameters then quote it.
          Be strict: if your job is ok then exit wit returncode 0.
          If an error occurs exit with returncode <> 0.
  
  LABEL   optional: label to be used as output filename
          If not set it will be detected from basename of executed command.
          When you start a script with different parameters it is highly
          recommended to set the label.


####| 📝 REMARK |####

  You don't need to redirect the output in a cron config file. STDOUT and
  STDERR will be fetched automaticly. 
  It also means: Generate as much output as you want and want to have to debug
  a job in error cases.


####| 🗨 MORE TO SAY |####

  The output directory of all jobs executed by ./cronwrapper.sh is
  /var/tmp/cronlogs.
  The output logs are parseble with simple grep command.

  You can run /opt/cronwrapper/cronstatus.sh to get a list of all cronjobs and 
  its status. Based on its output you can create a check script for your 
  server monitoring.

  You can sync all logfiles of all cronjobs to a defined server using
  /opt/cronwrapper/cronlog-sync.sh

```

## Replace existing Cronjobs

I am sure you already have some cronjobs on your systems :-)

You don't need to rewrite anything - we add the wrapper only.

As an example ... if you have a daily cronjob like this starting at 3:12 am:

```bash
7 * * * * root /opt/mybackup/backup.sh >/var/log/cronjobs/my-backup.log 2>&1
```

To use my wrappper

* add the wrapper in front
* add a TTL (in minutes) as first param. It defines how often this job is called. This will let us detect if a job is out of date.
* add the command as third param - if you use arguments, then you need to quote it
* optional: add a label for the output file (it overrides the default naming convention of the log)
* remove the output redirections

The cronjob above needs to be rewritten like that:

```bash
12 3 * * * root /opt/cronwrapper/cronwrapper.sh 60 /opt/mybackup/backup.sh "my-backup"
```

![Rewrite an existing cronjob](images/rewrite_a_cronjob.drawio.png)

To test it immediately run the cron command line with its user:

```bash
/opt/cronwrapper/cronwrapper.sh 60 /opt/mybackup/backup.sh "my-backup"
```

You may ask: And what is the difference now?
First: your task does the same thing(s) like before.

But we us a wrapper with its functions described on top.

Run `cronstatus.sh`.

And then have a look to the generated files in `/var/tmp/cronlogs/`. And the next chapter.