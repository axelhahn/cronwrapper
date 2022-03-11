
# Introduction

This Bash script `inc_cronfunctions.sh` contains a few helpful functions for your cronjob scripts. If you write them as Bash scripts too.

You need to source it in the beginning of your cronjob script.

```bash
#!/bin/bash
(...)
. /usr/local/bin/inc_cronfunctions.sh
(...)
```

This adds a variable rcAll and a few functions.

# functions

After sourcing inc_cronfunctions.sh you get a list of available function with `cw.help`.

```txt
HELP FOR CRONWRAPPER FUNCTIONS
auto generated list of implemented cw.* functions

cw.cecho
    colored echo output using color and reset color afterwards
    param  string  color code ... see cw.color
    param  string  text to display
    
    Example:
    cw.cecho ok "Action was successful."

cw.color
    set a terminal color by a keyword
    param  string  keyword to set a color; one of reset | head|cmd|input | ok|warning|error
    
    Example:
    color cmd
    ls -l 
    color reset

cw.exec
    execute a given command, show return code (and add it to final exit code)
    param  string(s)  command line to execute 

cw.fetchRc
    get last exitcode and store it in global var $rc
    no parameter is required

cw.help
    show help for available cw.* functions
    no parameter required

cw.lock
    verify locking and create one if no active lock was found
    param  string  optional: string to create sonething uniq if your script can 
                   be started with multiple parameters
    see cw.lockstatus, cw.unlock

cw.lockstatus
    check status of locking
    exit code is 0 if locking is active
    Example: if cw.lockstatus; then echo Lock is ACTIVE; else echo NO LOCKING; fi
    see cw.lock, cw.unlock

cw.quit
    quit script with showing the total exitcode.
    no parameter is required

cw.randomsleep
    sleep for a random time
    param  integer  time to randomize in sec
    param  integer  optional: minimal time to sleep in sec; default: 0
    
    Example: 
    cw.randomsleep 60     sleeps for a random time between 0..60 sec
    cw.randomsleep 60 30  sleeps for a random time between 30..90 sec

cw.timer
    get time in sec and milliseconds since start
    no parameter is required

cw.unlock
    remove an existing locking
    no parameter is required
    see cw.lock, cw.lockstatus

```

## example script

```bash
#!/bin/bash
. /usr/local/bin/inc_cronfunctions.sh

cw.exec rsync -rav /my/source/dir/ /my/target/dir/

# ... add command 2 here ...
# cw.fetchRc

# ... add command 3 here ...
# cw.fetchRc

# 
cw.quit

```
