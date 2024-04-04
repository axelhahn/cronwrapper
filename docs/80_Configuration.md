## Config file

To create a custom configuration file copy cronwrapper.cfg.dist to cronwrapper.cfg.

For local running cronjobs and watching their status by cronstatus.sh there is no real need to touch it.

If you want to use a sync of a changed logfile with cronlog-sync.sh then you need to watch the lower section.

```txt
# -----------------------------------------------------------------------------
# CRONWRAPPER * config
# -----------------------------------------------------------------------------

# ----- shared values:
CW_LOGDIR=/var/tmp/cronlogs


# ----- for cronwrapper
# deny multiple execution of the same job? set 0 or 1
CW_SINGLEJOB=1

# directory with hooks
CW_HOOKDIR=./hooks


# ----- for sync of local logs
CW_TOUCHFILE=lastsync
CW_TARGET=get-cronlogs@cronlogviewer.example.com:/var/tmp/allcronlogs/$( hostname -f )
CW_SSHKEY=/root/.ssh/id_rsa_get-cronlogs@cronlogviewer.example.com

# force rsync even if no change was found - time in sec
CW_SYNCAFTER=3600

# disallow hosts that have no domain in hostname -f; set 0 or 1
CW_REQUIREFQDN=0

# -----------------------------------------------------------------------------
```

For the execution of all cronjobs on the server there is just one variable to define a place where to store output files.

Variable     | type   | description
---          |---     |---
CW_LOGDIR    | string | Ouput dir of all logfiles when using cronwrapper.<br>It is used by status script and sync script to read data from here. Default: "/var/tmp/cronlogs"
CW_SINGLEJOB | int    | 0 or 1; 1=deny multiple execution of the same job (default)
CW_HOOKDIR   | string | set an absolute directory to the hooks directory; use it if you use a created a softlink for the cronwrapper to /usr/local/bin and want to point to the real install directory; default: ./hooks; changing it is not needed

For an optional rsync script to collect all logs of all servers on a central server (see [Cronlog-Sync](40_More/50_Cronlog-Sync.md)):

Variable     | type   | description
---          |---     |---
CW_TOUCHFILE | string | sync: filename of touch file to mark a timestamp of the last sync (created in in $CW_LOGDIR); eg. "lastsync"
CW_TARGET    | string | ssh target where to sync files from $LOGFILE with `sshuser@targethost:/path`<br>Default: `get-cronlogs@cronlogviewer.example.com:/var/tmp/allcronlogs/\$( hostname -f )`
CW_SSHKEY       | string | filename to ssh private key to connect passwordless to $TARGET
CW_SYNCAFTER    | int    | time in sec; default: 3600 (1h); time before syncing the logdir even if it has noch change
CW_REQUIREFQDN  | int    | 0 or 1; block sync if `hostname -f` has no FQDN

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