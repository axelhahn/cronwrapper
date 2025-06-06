## 2025

### 2025-05-06 - v2.5

* FIX: cronstatus - ignore false binary detection of grep

### 2025-02-24 - v2.4

* FIX: cronstatus - Hide error of missing logfile before 1st job was executed
* UPDATE: bashdoc in cronstatus

## 2024

### 2024-04-08 - v2.3

* FIX/ UPDATE: remove `set -eu -o pipefail` because of unexpected behaviours
* UPDATE: use version number of inc_cronfunctions.sh in all scripts

### 2024-04-04 - v2.2

* ADDED: cronstatus.sh - skip intro header (-i)
* UPDATE: harden against bash pipefail option

### 2024-04-04 - v2.1

* ADDED: cronstatus.sh - skip intro header (-i)
* UPDATE: harden against bash pipefail option

### 2024-04-03 - v2.0

**Changes**

* ADDED: hooks - execute your own script before and after each cronjob
* ADDED: Support for `NO_COLOR=1`
* ADDED: emoji support (only if NO_COLOR is not 1 and is supported)
* UPDATE: enhanced output for `cronstatus.sh`: show a table with last executions (max. 10 per job)
* UPDATE: `cronstatus.sh` got more cli parameter options
* UPDATE: renamed variables with prefix "CW_" (for cron wrapper)
* UPDATE: keep stats of returncodes and execution time for custom time (before: 4 days [fixed]; now: 14 days [can be configured with CW_KEEPDAYS])

**Upgrade guide from former versions**

* Update your *cronwrapper.cfg* ... (or copy cronwrapper.cfg.dist to cronwrapper.cfg an update the values)
  * add the prefix "CW_" for existing vars which are now, eg.
    * CW_LOGDIR
    * CW_SINGLEJOB
    * CW_TOUCHFILE
  * optional: add new variables (see also *cronwrapper.cfg.dist*)
    * CW_KEEPDAYS=N where N ist the number of days to keep history of returncodes and execution time; default is 14 (days)
    * CW_HOOKDIR (not needed to change)

## Many years between

There were 26 minor versions v1.x.
There is no changelog for them - but have a look into head section of cronwrapper.sh for some infos.

## 2002

### 2002-02-06 - v1.0
