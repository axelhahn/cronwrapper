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