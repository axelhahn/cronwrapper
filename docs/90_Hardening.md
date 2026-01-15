## Hardening

To prevent world writable files and limit the permissions:

* in cronwrapper.cfg define the permissions:
  * CW_LOGDIR_PERMS=0700
  * CW_LOGFILE_PERMS=600
  * When you sync Cronjob logs to a central server using `cronlog-sync.sh` then you can set 0755 and 644
* Start all cronjobs as root.
* For non-root jobs and use `su - <user> -s /bin/sh -c "<command>"`. The `-s` options defines a shell that allows to switch to any user that has no default shell in /etc/passwd

**Example**:

A cleanup job started as root and switching to context of another user

```txt
25 21 * * * root /opt/cronwrapper/cronwrapper.sh 1440 'su - www-data -s /bin/sh -c "find /var/www/cache/ -maxdepth 1 -type d -mtime +7 | sort -r | xargs rm -rf"' 'cleanup'
```
