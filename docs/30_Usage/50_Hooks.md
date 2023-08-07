# Hooks

Hooks are points during the cronjob process where you can execute custom scripts at the beginning, at the end and during the process.

All hooks are located in the `./hooks/` directory.

We have hooks “before” a job starts and “afterwards”.

Below all hook directories have the subdirectory “always”: `./hooks/[Name-of-hook]/always/`

```txt
hooks
|-- after
|   |-- always
|   |-- on-error
|   `-- on-ok
`-- before
    `-- always
```

## “before” actions

They don’t know an execution status of something. They can execute only scripts that are located in “always” subdirectory.

## “after” actions

The “afterwards” added hooks know the execution status of the last action. That’s why in the hook directory we have additionally the subdirs

    ./hooks/[Name-of-hook]/on-ok/ - the last action was 0 (zero)
    ./hooks/[Name-of-hook]/on-error/ - if the exitcode was non-zero

After execution of the scripts of “on-ok” or “on-error” folder. Then additionally the found scripts of “always” folder will be executed.

## Order of multiple scripts

You can place multiple scripts into the subdirs on-ok|on-error|always. To be executed a file must have execution permissions.

Their order for execution is alphabetic (by using the sort command). Suggestion is to add numbers in front of a script name.

## What variables you can access..

Your hooks maybe want to access a few information to send a notification or whatever.
These data may help you to generate a message.

| variable     | type     | description |
|---           |---       |---          |
| CALLSCRIPT   | {string} | executed command line |
| FINALOUTFILE | {string} | filename of the final logfile of the job to send as information |
| LABELSTR     | {string} | label of the job|
| OUTFILE      | {string} | filename of the still running cronjob (for after/*/*); you can grep its content eg. "^SCRIPTOUT=" (see Output)  |
| MYHOST       | {string} | hostname|
| TTL          | {int}    | ttl value in minutes|
| iStart       | {int}    | Unix timestamp of the starting time|
| iEnd         | {int}    | Unix timestamp of the ending time (for after/*/*)|
| iExectime    | {int}    | execution time in seconds (for after/*/*)|
| rc           | {int}    | resturncode of the failed job (for after/on-error/*)|

## Example

### Send an email if a job failed

Remark: 
To send an email you need to install a mailer like sendmail or postfix locally and configure it to be able to send trusted emails via your smtp gateway.

Create a script as root eg. `hooks/after/on-error/send_email.sh`.
Make it executable `chmod 0755 hooks/after/on-error/send_email.sh`

Content of *send_email.sh*:

```shell
#!/bin/bash

TO=sysadmin@example.com
SUBJECT="Cronjob on ${MYHOST} - ${LABELSTR} failed with rc=${rc}"

cat "${OUTFILE}" | mail -s "${SUBJECT}" ${TO}
```
