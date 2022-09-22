# Create config file

Copy cronwrapper.cfg.dist to cronwrapper.cfg.

```txt
# -----------------------------------------------------------------------------
# config
# -----------------------------------------------------------------------------

# ----- shared values:
LOGDIR=/var/tmp/cronlogs

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

Variable  | type   | description
---       |---     |---
LOGDIR    | string | Ouput dir of all logfiles when using cronwrapper.<br>It is used by status script and sync script to read data from here

For sync script to a central server

Variable    | type   | description
---         |---     |---
TOUCHFILE   | string | sync: filename of touch file to mark a timestamp of the last sync (in $LOGDIR)
TARGET      | string | ssh target where to sync files from $LOGFILE with `sshuser@targethost:/path`<br>Default: `get-cronlogs@cronlogviewer.example.com:/var/tmp/allcronlogs/\$( hostname -f )`
SSHKEY      | string | filename to ssh private key to connect passwordless to $TARGET
SYNCAFTER   | int    | time in sec; default: 3600 (1h); time before syncing the logdir even if it has noch change
REQUIREFQDN | int    | 0 or 1; block sync if `hostname -f` has no FQDN