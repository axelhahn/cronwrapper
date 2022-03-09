
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
cw.cecho
    colored echo output using color and reset color afterwards
    param  string  color code ... se cw.color
    param  string  text to display

cw.color
    set a terminal color by a keyword
    param  string  keyword to set a color; one of reset | head|cmd|input | ok|warning|error

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
    param  string  optional: string to create sonething uniq if your script can be started with multiple parameters

cw.quit
    quit script with showing the total exitcode.
    no parameter is required

cw.timer
    get time in sec and milliseconds since start
    no parameter is required

cw.unlock
    remove an existing locking
    no parameter is required
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
