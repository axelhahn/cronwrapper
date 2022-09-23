#!/bin/bash
# ======================================================================
#
# CRONLOG SYNC
#
# ----------------------------------------------------------------------
# This script makes an rsync to monitor target
# 2019-09-12  v1.0  <axel.hahn@iml.unibe.ch>  first lines
# 2022-09-21  v1.1  <axel.hahn@iml.unibe.ch>  add ssh key
# 2022-09-22  v1.2  <axel.hahn@iml.unibe.ch>  optional: stop if hostname has no domain
# 2022-09-23  v1.3  <axel.hahn@iml.unibe.ch>  fix exitcode on no sync and failed sync
# ======================================================================

_version=1.3

LOGDIR=/var/tmp/cronlogs
TARGET=
SSHKEY=
typeset -i SYNCAFTER=3600
typeset -i REQUIREFQDN=0

. $( dirname $0)/inc_cronfunctions.sh
CFGFILE=$(dirname $0)/cronwrapper.cfg
. "${CFGFILE}"

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

function showHelp(){
    local self=$( basename $0)
cat <<ENDOFHELP
HELP:
    This script syncs local cronlogs to a target
    It should be used as cronjob in /etc/cron.d/

SYNTAX:
    $self [OPTIONS]

PRAMETERS:
    -h            show this help
    -s [integer]  sleep random time .. maximum is given value in seconds
    -l [string]   local  log dir of cronjobs
                  current value: [$LOGDIR]
    -t [string]   target dir (local or remote like rsync syntax)
                  current value: [$TARGET]
    -i [string]   path to ssh private key file
                  current value: [$SSHKEY]

DEFAULTS:
    see also ${CFGFILE}

EXAMPLES:
    $self -s 20 -t [TARGET] - wait max 20 sec before starting sync

ENDOFHELP
}

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

cat <<ENDOFHEAD
____________________________________________________________________________________

SNYC LOCAL LOGS OF $( hostname -f )
______________________________________________________________________________/ v$_version

ENDOFHEAD

while getopts ":h :i: :l: :s: :t:" opt
do
        case $opt in
                h)
                        showHelp
                        exit 0
                        ;;
                s)
                        typeset -i iSleep=$(($RANDOM%$OPTARG))
                        echo "DEBUG: random sleep $iSleep sec - maximum $OPTARG sec was given"
                        sleep $iSleep
                        ;;
                i)
                        SSHKEY=$OPTARG
                        echo "DEBUG: set ssh key to ${SSHKEY}"
                        ;;
                l)
                        LOGDIR=$OPTARG
                        echo "DEBUG: local log dir was set to ${LOGDIR}"
                        ;;
                t)
                        TARGET=$OPTARG
                        echo "DEBUG: target was set to ${TARGET}"
                        ;;
                :)
                        cw.cecho error "ERROR: Option -$OPTARG requires an argument." >&2
                        showHelp
                        exit 1
                        ;;
                *)
                        cw.cecho error "ERROR: $opt is unknown." >&2
                        showHelp
                        exit 1
        esac
done
if ! hostname -f | grep "\." >/dev/null; then
    echo "REQUIREFQDN=$REQUIREFQDN"
    test "$REQUIREFQDN" != "0" && cw.cecho error "ERROR: hostname [$( hostname -f )] is not a FQDN - there is no domain behind the host."
    test "$REQUIREFQDN" != "0" && exit
fi


if [ -z "$TARGET" ]; then
  cw.cecho error ERROR: no target was set. use -t >&2
  echo
  showHelp
  exit 2
fi

echo "----- local data in ${LOGDIR}"
ls -l "${LOGDIR}" || exit 3

echo
echo "----- test for files to sync"

if ls -ltr "${LOGDIR}" | tail -1 | grep "$TOUCHFILE" >/dev/null
then
    echo "NO newer logs"
    typeset -i age=$(($(date +%s) - $(date +%s -r "${LOGDIR}/${TOUCHFILE}")))
    echo "last sync was $age sec ago (limit: $SYNCAFTER sec)."
    if test $age -gt $SYNCAFTER
    then
        echo "Force sync because last sync is older the given limit."
    else 
        echo "No sync is needed."
        exit 0
    fi
else
    echo "Need to sync: logs were not synced yet."
fi

echo
echo "----- sync to ${TARGET}"
moreparams=
if test -n "$SSHKEY"; then
    # moreparams="-e 'ssh -i $SSHKEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"
    moreparams="-e ssh -i ${SSHKEY} -o StrictHostKeyChecking=no"

fi

if /usr/bin/rsync --delete -rvt "${moreparams}" "${LOGDIR}/" "${TARGET}"
then 
    echo "OK, files were synced"
    touch "${LOGDIR}/${TOUCHFILE}" && chmod 666 "${LOGDIR}/${TOUCHFILE}"
else
    echo "ERROR while syncing files. Next run will try to sync again."
    rm -f "${LOGDIR}/$TOUCHFILE" 2>/dev/null
    exit 2
fi

# ----------------------------------------------------------------------
