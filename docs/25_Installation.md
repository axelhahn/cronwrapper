# Get the files

## Download

Go to https://github.com/axelhahn/cronwrapper and download the archive and extract it
in `/opt/cronwrapper/`

## Git clone

Or clone the repository

`cd /opt/` and `git clone https://github.com/axelhahn/cronwrapper.git`

# Symlinks to /usr/local/bin

This is optional. If you love to use the cronwrapper.sh with /usr/local/bin/ instead of /opt/cronwrapper/ (because of optical reaons) you can create softlinks (as root):

```bash
cd /usr/local/bin/
ln -s /opt/cronwrapper/cronstatus.sh
ln -s /opt/cronwrapper/cronwrapper.sh
ln -s /opt/cronwrapper/inc_cronfunctions.sh
```

# Permissions

In a fresh download / git clone it is not needed to change something. This is just for documentation.

We need `0755` permission (execute for all) on scripts that can be executed:

```text
cronstatus.sh
cronwrapper.sh
```

We need `0644` permission (readable for all) on the file that will be sourced:

```text
inc_cronfunctions.sh
```

# A first test

## Run a job

With an unpriviledged user start the command in a terminal:

```text
axel@linux-pc ~> /opt/cronwrapper/cronwrapper.sh 1 ls
```

## Status

This starts the ls command and sets a ttl value of 1 minute.
You don't get any outout. That is the wanted behaviour for cronjobs.
Let's have a look to status of all started cronwrapper jobs:

```text
axel@linux-pc ~> /opt/cronwrapper/cronstatus.sh 
____________________________________________________________________________________

CRONJOBS on [linux-pc]
______________________________________________________________________________/ v1.9

--- /var/tmp/cronlogs/linux-pc_ls.log

    command   : ls
    last start: 2023-07-31 13:39:24, 1690803564
    returncode: 0 OK
    duration  : 0 s
    ttl       : 1 min OK
    expires   : 1690803684 2023-07-31 13:41:24 OK
    CHECK OK
```

If you wait more than a minute and repeat the command, you see 

```text
axel@linux-pc ~> /opt/cronwrapper/cronstatus.sh
____________________________________________________________________________________

CRONJOBS on [linux-pc]
______________________________________________________________________________/ v1.9

--- /var/tmp/cronlogs/linux-pc_ls.log

    command   : ls
    last start: 2023-07-31 13:39:24, 1690803564
    returncode: 0 OK
    duration  : 0 s
    ttl       : 1 min OK
    expires   : 1690803684 2023-07-31 13:41:24 <<<<<<<<<< ERROR
    CHECK FAILED
```

## Details

You can start the *cronstatus.sh* and add a logfile to see a detailed log of the job:

```text
/opt/cronwrapper/cronstatus.sh /var/tmp/cronlogs/linux-pc_ls.log
...
```
