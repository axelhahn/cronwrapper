# Axels Cronwrapper

Unix shell scripts to make it easier to handle the status of cronjobs.

GNU GPL 3.0



## Introduction

Default Unix and linux cronjobs are quite basic stuff. Mostly you create
"simple, stupid" jobs without output ... that just run. Or should.

If you use cronjob you need to hide the output otherwise the root user gets an 
email. So if you generate the output and have many cronjobs then you need a 
convention how to name your log files.

How do you check if a job was successful? Watching each log?

How do you detect if the last job was successful but does not run anymore?

## Cronwrapper

### Installation

Copy the 3 shellscript files somewhere. I suggest /usr/local/bin/.
If you use ansible, puppet, ... use a file comand to put it to all
your systems into the same directory.

### Usage

As an example ... if you have a cronjob like this:

```bash
12 3 * * * root /usr/local/bin/my-database-dumper.sh
```

Using my wrappper 
* you add the wrapper in front
* add a TTL (in minutes) as first param
* add the command as third param - if you use arguments, then you need to quote it
* optional: add a label for the output file (it overrides the default naming convention of the log)

The cronjob above needs to be rewritten like that:
```bash
12 3 * * * root /usr/local/bin/cronwrapper.sh 1440 /usr/local/bin/my-database-dumper.sh
```

### Advantages

Just using a wrapper breaks tons of limits! Suddenly you can do so many things.
What my wrapper does:

* The wrapper fetches any output and creates a log file with the name of the started script 
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
	error occurs
  * all metadata and the output will be written in a log file with parsable
    syntax! Just using grep and cut you could verify all your jobs. But there is
	an additional check script too.
  * The TTL value (parameter 2) generates a file with a timestamp. The check 
    script detects with it if a cronjob log is outdated

TO BE CONTINUED