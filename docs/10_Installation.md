# Get the files

## Download

Go to https://github.com/axelhahn/cronwrapper and download the archive and extract it.

## Git clone

Or clone the repository

`git clone https://github.com/axelhahn/cronwrapper.git`

# Copy shellscripts

Copy all shellscript files somewhere.

```text
cronstatus.sh
cronwrapper.sh
inc_cronfunctions.sh
```

In my examples I use

```bash
/usr/local/bin/
```

To copy it to /usr/local/bin it requires root permissions.

`cp *.sh /usr/local/bin/`

# Permissions

In a fresh download / git clone it is not needed to change something.

This is just for documentation.

We need `0755` permission (execute for all) on scripts that can be executed:

```text
cronstatus.sh
cronwrapper.sh
```

We need `0644` permission (readable for all) on the file that will be sourced:

```text
inc_cronfunctions.sh
```

