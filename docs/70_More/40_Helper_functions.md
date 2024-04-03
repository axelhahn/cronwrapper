## Introduction

This Bash script `inc_cronfunctions.sh` contains a few helpful functions for your cronjob scripts. If you write them as Bash scripts too.

You need to source it in the beginning of your cronjob script.

```bash
#!/bin/bash
(...)
. /opt/cronwrapper/inc_cronfunctions.sh || exit 1
(...)
```

This adds a variable rcAll and a few functions.

## Functions

After sourcing inc_cronfunctions.sh you get a list of available function with `cw.help`.

```txt

HELP FOR CRONWRAPPER FUNCTIONS * v2.0
auto generated list of implemented cw.* functions

cw.cecho
    Colored echo output using color and reset color afterwards
    see also: cw.color
    
    Example:
      cw.cecho ok "Action was successful."
    
    param   string  color code ... see cw.color
    param   string  text to display


cw.color
    Set a terminal color by a keyword
    Example:
      cw.color cmd
      ls -l 
      color reset
    
    global  integer  $NO_COLOR  value 1 means: no color please; see http://no-color.org/
    
    param   string  keyword to set a color; one of reset | head|cmd|input | ok|warning|error


cw.emoji
    Show a given emoji if its display is supported
    
    Example
      echo $( cw.emoji "📜" )License: GNU GPL 3.0
    
    global  integer  $NO_COLOR  value 1 means: no color please; see http://no-color.org/
    
    param   string  emoji to show
    param   string  alternative text for NO_COLOR=1 output


cw.exec
    Execute a given command, show return code (and add it to final exit code)
    param   string  command line to execute 


cw.fetchRc
    Get last exitcode and store it in global var $rc
    no parameter is required
    
    global  integer  $rcAll  sum of retuncodes of all commands


cw.help
    Show help for available cw.* functions
    no parameter required


cw.helpsection
    Print a headline for a help section
    param   string  emoji
    param   string  headline text


cw.lock
    Verify locking and create one if no active lock was found
    see also: cw.lockstatus, cw.unlock
    
    global  string  $CW_lockfile  filename of the lockfile
    
    param   string  optional: string to create sonething uniq if your script can 
                   be started with multiple parameters


cw.lockstatus
    Check status of locking
    exit code is 0 if locking is active
    see also: cw.lock, cw.unlock
    
    Example: if cw.lockstatus; then echo Lock is ACTIVE; else echo NO LOCKING; fi
    
    global  string  CW_lockfile  filename for locking


cw.quit
    Quit script with showing the total exitcode.
    
    global  integer  $rcAll  sum of retuncodes of all commands
    
    no parameter is required


cw.randomsleep
    Sleep for a random time
    
    param  integer  time to randomize in sec
    param  integer  optional: minimal time to sleep in sec; default: 0


cw.timer
    Get time in sec and milliseconds since start
    
    global  integer  $CW_timer_start  start time in sec
    
    no parameter is required


cw.unlock
    Remove an existing locking
    no parameter is required
    see also: cw.lock, cw.lockstatus
    
    global  string  CW_lockfile  filename for locking

```

### example script

```bash
#!/bin/bash
. /opt/cronwrapper/inc_cronfunctions.sh

cw.exec rsync -rav /my/source/dir/ /my/target/dir/

# ... add command 2 here ...
# cw.fetchRc

# ... add command 3 here ...
# cw.fetchRc

# 
cw.quit

```
