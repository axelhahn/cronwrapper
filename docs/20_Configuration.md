## Config file

To create a custom configuration file copy cronwrapper.cfg.dist to cronwrapper.cfg.

The file needs read permissions for all users (0644).

```txt
# -----------------------------------------------------------------------------
# CRONWRAPPER * config
# -----------------------------------------------------------------------------

# ----- shared values:
LOGDIR=/var/tmp/cronlogs


# ----- for cronwrapper
# deny multiple execution of the same job? set 0 or 1
SINGLEJOB=1


# ----- for sync of local logs
TOUCHFILE=lastsync
TARGET=get-cronlogs@cronlogviewer.example.com:/var/tmp/allcronlogs/$( hostname -f )
SSHKEY=/root/.ssh/id_rsa_get-cronlogs@cronlogviewer.example.com

# force rsync even if no change was found - time in sec
SYNCAFTER=3600

# disallow hosts that have no domain in hostname -f; set 0 or 1
REQUIREFQDN=0

# -----------------------------------------------------------------------------
```

For the execution of all cronjobs on the server there is just one variable to define a place where to store output files.

Variable  | type   | description
---       |---     |---
LOGDIR    | string | Ouput dir of all logfiles when using cronwrapper.<br>It is used by status script and sync script to read data from here. Default: "/var/tmp/cronlogs"
SINGLEJOB | int    | 0 or 1; 1=deny multiple execution of the same job (default)

For an optional rsync script to collect all logs of all servers on a central server (see [Cronlog-Sync](30_Usage/50_Cronlog-Sync.md)):

Variable    | type   | description
---         |---     |---
TOUCHFILE   | string | sync: filename of touch file to mark a timestamp of the last sync (created in in $LOGDIR); eg. "lastsync"
TARGET      | string | ssh target where to sync files from $LOGFILE with `sshuser@targethost:/path`<br>Default: `get-cronlogs@cronlogviewer.example.com:/var/tmp/allcronlogs/\$( hostname -f )`
SSHKEY      | string | filename to ssh private key to connect passwordless to $TARGET
SYNCAFTER   | int    | time in sec; default: 3600 (1h); time before syncing the logdir even if it has noch change
REQUIREFQDN | int    | 0 or 1; block sync if `hostname -f` has no FQDN

## Environment file

In a environment file you can set a pre defined shell environment for all your cronwrapper cronjobs. This is completely optional. Just keep in mind that the possibility exist if it is needed once.

To create a custom environment file copy cronwrapper.env.dist to cronwrapper.env.
The file needs read permissions for all users (0644).

```bash
# -----------------------------------------------------------------------------
# CRONWRAPPER * environment
# -----------------------------------------------------------------------------

# export PATH=$PATH:...
# umask 0022

# -----------------------------------------------------------------------------
```