
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

## exec2

It is a replacement for exec. It shows the executed command and executes it. Finally it calls fetchRc to save the return code.

## fetchRc

This function fetches the returncode from \$?, shows it on stdout and incremets \$rcAll with it.
At the end of the script (or at any point) you have a \$rcAll = 0 if every command was successful. And \$rcAll <> 0 if any of it failed.

## quit

Exit the scipt with the value of \$rcAll.
So your scscript exits with exitcode = 0 if every command was successful. And exitcode <> 0 if any of it failed.

## example script

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
