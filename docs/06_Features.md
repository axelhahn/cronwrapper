## Features

### Cronwrapper

* No need to redirect the cronjobs
* Created log has a normalized syntax and can be parsed with simple grep
* Block multiple instances of the same job
* Hooks ✴️ new in 2.0

### Monitoring

The normalized syntax offers simple access to several metadata like

* executed command
* start time/ end time/ execution time/ ttl
* exitcode
* output

cronstatus.sh shows the overview of all local cronjobs using cronwrapper and details for a single job

* Show error for non-zero exitcode 
* Show error for non starting jobs using the given ttl per job
* Warn if execution time is larger ttl
* Get history of return codes

### Helper functions

You optionally can add the file `inc_cronfunctions` into your script. It offers several helpers, eg

* fetch returncodes of a command
* lock/ unlock
* colored output
* timer
