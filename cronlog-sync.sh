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
# 2022-09-23  v1.4  <axel.hahn@iml.unibe.ch>  option -q is more quiet and -f to set SYNCAFTER
# 2023-07-21  v1.5  <axel.hahn@iml.unibe.ch>  fix typo in header
# ======================================================================

_version=1.5

LOGDIR=/var/tmp/cronlogs
TARGET=
SSHKEY=
typeset -i SYNCAFTER=3600
typeset -i REQUIREFQDN=0
typeset -i VERBOSE=1

. $( dirname $0)/inc_cronfunctions.sh
CFGFILE=$(dirname $0)/cronwrapper.cfg
. "${CFGFILE}"

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

function showHead(){
cat <<ENDOFHEAD
____________________________________________________________________________________

SYNC LOCAL LOGS OF $( hostname -f )
______________________________________________________________________________/ v$_version

ENDOFHEAD
}

function showHelp(){
    showHead
    local self=$( basename $0)
cat <<ENDOFHELP
HELP:
    This script syncs local cronlogs to a target.
    It should be used as cronjob in /etc/cron.d/ and/ or triggered
    whem any cronwrapper script was fisnished.

SYNTAX:
    $self [OPTIONS]

PRAMETERS:
    -f [integer]  time in sec when to force symc without new logs
                  value 0 forces sync
                  current value: [$SYNCAFTER]
    -h            show this help
    -i [string]   path to ssh private key file
                  current value: [$SSHKEY]
    -l [string]   local  log dir of cronjobs
                  current value: [$LOGDIR]
    -q            be more quiet
    -s [integer]  sleep random time .. maximum is given value in seconds
    -t [string]   target dir (local or remote like rsync syntax)
                  current value: [$TARGET]

DEFAULTS:
    see also ${CFGFILE}

EXAMPLES:
    $self -s 20 -t [TARGET]   wait max 20 sec before starting sync
    $self -q -f 0             be more quiet and force sync (0 sec)

ENDOFHELP
}

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

while getopts ":f: :h :i: :l: :q :s: :t:" opt
do
    case $opt in
        h)
            showHelp
            exit 0
            ;;
        f)
            SYNCAFTER=$OPTARG
            ;;
        i)
            SSHKEY=$OPTARG
            ;;
        l)
            LOGDIR=$OPTARG
            ;;
        q)
            VERBOSE=0
            ;;
        s)
            typeset -i iSleep=$(($RANDOM%$OPTARG))
            echo "Random sleep $iSleep sec - maximum $OPTARG sec was given"
            sleep $iSleep
            ;;
        t)
            TARGET=$OPTARG
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

test $VERBOSE -ne 0 && showHead

if ! hostname -f | grep "\." >/dev/null; then
    test "$REQUIREFQDN" != "0" && cw.cecho error "ERROR: hostname [$( hostname -f )] is not a FQDN - there is no domain behind the host."
    test "$REQUIREFQDN" != "0" && exit
fi

if [ -z "$TARGET" ]; then
  cw.cecho error ERROR: no target was set. use -t >&2
  echo
  showHelp
  exit 2
fi

if [ $VERBOSE -ne 0 ]; then
    echo "----- local data in ${LOGDIR}" && ls -l "${LOGDIR}" || exit 3
    echo
    echo "----- test for files to sync"
else
    ls -l "${LOGDIR}" >/dev/null || exit 3
fi


if ls -ltr "${LOGDIR}" | tail -1 | grep "$TOUCHFILE" >/dev/null
then
    echo -n "NO newer logs. "
    typeset -i age=$(($(date +%s) - $(date +%s -r "${LOGDIR}/${TOUCHFILE}")))
    echo -n "last sync was $age sec ago (limit: $SYNCAFTER sec). "
    if test $age -gt $SYNCAFTER
    then
        echo "Force sync because last sync is older the given limit."
    else 
        echo "No sync is needed."
        exit 0
    fi
else
    echo "Need to sync: new files were not synced yet."
fi

test $VERBOSE -ne 0 && echo && echo "----- sync to ${TARGET}"

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
