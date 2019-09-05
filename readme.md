Axels

```
 ______                        ________                                    
|      |.----.-----.-----.    |  |  |  |.----.---.-.-----.-----.-----.----.
|   ---||   _|  _  |     |    |  |  |  ||   _|  _  |  _  |  _  |  -__|   _|
|______||__| |_____|__|__|    |________||__| |___._|   __|   __|_____|__|  
                                                   |__|  |__|              
```

Unix shell scripts to make it easier to handle cronjobs.
A little idea that offers more possibilities.

Free software and Open source.
GNU GPL 3.0

# Introduction

Default Unix and linux cronjobs are quite basic stuff. Mostly you create
"simple, stupid" jobs without output ... that just run. Or should.

If you use a cronjob you need to hide the output otherwise the root user gets an 
email. So if you generate the output and have many cronjobs then you need a 
convention how to name your log files.

Questions:
* How do you check if a job was successful? Watching each log? On each System? Just trust?
* How do you detect if the last job execution was successful but does not run anymore?

My simple approach: Just using a wrapper in front of your command breaks tons of limits! Suddenly you can do so many things.

# Requirements

Linux system with installed bash.
Tested on CentOS, Debian, Ubuntu.

# Installation

Copy all shellscript files somewhere. I suggest 
```bash
/usr/local/bin/
```
# Cronwrapper

If you use ansible, puppet, ... use a file comand to put it to all
your systems into the same directory.

## Replace existing Cronjobs

As an example ... if you have a daily cronjob like this starting at 3:12 am:

```bash
12 3 * * * root /usr/local/bin/my-database-dumper.sh
```

To use my wrappper 
* you add the wrapper in front
* add a TTL (in minutes) as first param. It defines how often this job is called. This will let us detect if a job is out of date.
* add the command as third param - if you use arguments, then you need to quote it
* optional: add a label for the output file (it overrides the default naming convention of the log)

The cronjob above needs to be rewritten like that:
```bash
12 3 * * * root /usr/local/bin/cronwrapper.sh 1440 /usr/local/bin/my-database-dumper.sh
```


To test it immediatly run con command line:
```bash
/usr/local/bin/cronwrapper.sh 1440 /usr/local/bin/my-database-dumper.sh
```

You may ask: And what is the difference now?
First: your task does the same thing(s) like before.

But what the additional wrapper does:

* The wrapper fetches any output of stdout + stderr and creates a log file with a name based on the started script 
  (remark: you can override the naming with the 3rd parameter).
  Do not try to keep silent anymore: write as many output as you want, write the output that you can understand the execution!
* The wrapper logs  a few things by itself: 
  * the started command
  * starting time
  * ending time
  * ... and having these: the execution time
  * the exitcode of the command/ script;
    This means: be strinct like all commands do! Write your cronjob script that
	ends with exitcode 0 if it is successful and quit with non-zero if any
	error occurs. Be strict!
  * The TTL value (parameter 2) generates a file with a timestamp. The check 
    script detects with it if a cronjob log is outdated
* all metadata and the output will be written in a log file with parsable
syntax! Just using grep and cut you could verify all your jobs. But there is
an additional check script too: run cronstatus.sh

## Output

Have look into the directory after your first job was run.
```bash
/var/tmp/cronlogs/
```

The wrapper stores 3 information in different files

* The output of the last execution of a job
* a flagfile with a timestamp in it
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

# Cronstatus

By starting the helper script 

```bash
/usr/local/bin/cronstatus.sh
```

it loops over all logfiles to see the last status of all your jobs (that were executed with the cronwrapper).

It shows the last execution time, the returncode and if the job is out of date.

# Include file inc_cronfunctions.sh

This Bash script contains a few helpfult functions for your cronjob scripts. If you write them as Bash scripts too.

## Initialisation

You need to source it in the beginning of your cronjob script.

```bash
#!/bin/bash
(...)
. /usr/local/bin/inc_cronfunctions.sh
(...)
```

This adds a variable rcAll and a few functions.

## functions

### exec2

It is a replacement for exec. It shows the executed command and executes it. Finally it calls fetchRc to save the return code.

### fetchRc

This function fetches the returncode from \$?, shows it on stdout and incremets \$rcAll with it.
At the end of the script (or at any point) you have a \$rcAll = 0 if every command was successful. And \$rcAll <> 0 if any of it failed.

### quit

Exit the scipt with the value of \$rcAll.
So your scscript exits with exitcode = 0 if every command was successful. And exitcode <> 0 if any of it failed.


### example script

```bash
#!/bin/bash
. /usr/local/bin/inc_cronfunctions.sh

exec2 rsync -rav /my/source/dir/ /my/target/dir/

# ... add command 2 here ...
fetchRc

# ... add command 3 here ...
fetchRc

# 
quit

```
