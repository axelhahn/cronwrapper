# Get the files

## Download

Go to https://github.com/axelhahn/cronwrapper and download the archive and extract it
in `/opt/cronwrapper/`

## Git clone

Or clone the repository

`cd /opt/` and `git clone https://github.com/axelhahn/cronwrapper.git`

# Copy shellscripts

You can copy all shellscript files somewhere:

```text
cronstatus.sh
cronwrapper.sh
inc_cronfunctions.sh
```

or create softlinks in /usr/local/bin.

```bash
cd /usr/local/bin/
ls -s /opt/cronwrapper/cronstatus.sh
ls -s /opt/cronwrapper/cronwrapper.sh
ls -s /opt/cronwrapper/inc_cronfunctions.sh
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
