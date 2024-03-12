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
# 2024-01-23  v1.6  ahahn                     update help; use cw.emoji; update exitcodes
# ======================================================================

_version=2.0
CW_LOGDIR=/var/tmp/cronlogs
CW_TARGET=
CW_SSHKEY=
typeset -i CW_SYNCAFTER=3600
typeset -i CW_REQUIREFQDN=0
typeset -i VERBOSE=1

. $( dirname $0)/inc_cronfunctions.sh
CFGFILE=$(dirname $0)/cronwrapper.cfg
. "${CFGFILE}"

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

function showHead(){
    cw.color head
cat <<ENDOFHEAD
______________________________________________________________________________

  AXELS CRONWRAPPER
  SYNC LOCAL LOGS OF $( cw.emoji "🖥️" )$( hostname -f )
$( printf "%78s" "v $_version" )
______________________________________________________________________________

ENDOFHEAD
    cw.color reset
}

function showHelp(){
    showHead
    local self=$( basename $0)
cat <<ENDOFHELP

This script syncs local cronlogs to a target.
It should be used as cronjob in /etc/cron.d/ and/ or triggered
whem any cronwrapper script was fisnished.

This script is part of Axels Cronwrapper.
  $( cw.emoji "📗" )Docs   : https://www.axel-hahn.de/docs/cronwrapper/
  $( cw.emoji "📜" )License: GNU GPL 3.0

$(cw.helpsection "✨" "SYNTAX")

  $self [OPTIONS]

$(cw.helpsection "🔧" "OPTIONS")

  -f [integer]  time in sec when to force symc without new logs
                value 0 forces sync
                current value: [$CW_SYNCAFTER]

  -h            show this help

  -i [string]   path to ssh private key file
                current value:
                [$CW_SSHKEY]

  -l [string]   local log dir of cronjobs
                current value:[$CW_LOGDIR]

  -q            be more quiet

  -s [integer]  sleep random time .. maximum is given value in seconds

  -t [string]   target dir (local or remote like rsync syntax)
                current value: 
                [$CW_TARGET]

$(cw.helpsection "🔷" "DEFAULTS")

  see ${CFGFILE}

$(cw.helpsection "🧩" "EXAMPLES")

  $self -s 20 -t [TARGET]
                Wait max. 20 sec before starting sync to a custom target

  $self -q -f 0
                be more quiet and force sync (0 sec)

$(cw.helpsection "❌" "EXITCODES")

  0             OK. Action ended as expected. No sync needed or sync was done.

  1             Missing parameter
  2             Invalid option
  3             No FQDN was found in hostname
  4             No target was set in configuration
  5             Target is still example.com
  6             Logdir with files to sync was not found
  7             rsync of local logs to target failed

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
            CW_SYNCAFTER=$OPTARG
            ;;
        i)
            CW_SSHKEY=$OPTARG
            ;;
        l)
            CW_LOGDIR=$OPTARG
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
            CW_TARGET=$OPTARG
            ;;
        :)
            cw.cecho error "ERROR: Option -$OPTARG requires an argument." >&2
            showHelp
            exit 1
            ;;
        *)
            cw.cecho error "ERROR: $opt is unknown." >&2
            showHelp
            exit 2
    esac
done

test $VERBOSE -ne 0 && showHead

if ! hostname -f | grep "\." >/dev/null; then
    test "$CW_REQUIREFQDN" != "0" && cw.cecho error "ERROR: hostname [$( hostname -f )] is not a FQDN - there is no domain behind the host."
    test "$CW_REQUIREFQDN" != "0" && exit 3
fi

if [ -z "$CW_TARGET" ]; then
  cw.cecho error ERROR: no target was set. use -t >&2
  echo
  showHelp
  exit 4
fi

if grep "example.com" <<< "$CW_TARGET"; then
    echo
    echo "ABORT: target is 'example.com'. You need to modify the configuration"
    echo "       file ${CFGFILE} and set the target to your own system."
    echo
    exit 5
fi

if [ $VERBOSE -ne 0 ]; then
    echo "----- local data in ${CW_LOGDIR}" && ls -l "${CW_LOGDIR}" || exit 6
    echo
    echo "----- test for files to sync"
else
    ls -l "${CW_LOGDIR}" >/dev/null || exit 6
fi


if ls -ltr "${CW_LOGDIR}" | tail -1 | grep "$CW_TOUCHFILE" >/dev/null
then
    echo -n "NO newer logs. "
    typeset -i age=$(($(date +%s) - $(date +%s -r "${CW_LOGDIR}/${CW_TOUCHFILE}")))
    echo -n "last sync was $age sec ago (limit: $CW_SYNCAFTER sec). "
    if test $age -gt $CW_SYNCAFTER
    then
        echo "Force sync because last sync is older the given limit."
    else 
        echo "No sync is needed."
        exit 0
    fi
else
    echo "Need to sync: new files were not synced yet."
fi

test $VERBOSE -ne 0 && echo && echo "----- sync to ${CW_TARGET}"

moreparams=
if test -n "$CW_SSHKEY"; then
    # moreparams="-e 'ssh -i $CW_SSHKEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"
    moreparams="-e ssh -i ${CW_SSHKEY} -o StrictHostKeyChecking=no"
fi

if /usr/bin/rsync --delete -rvt "${moreparams}" "${CW_LOGDIR}/" "${CW_TARGET}"
then 
    echo "OK, files were synced"
    touch "${CW_LOGDIR}/${CW_TOUCHFILE}" && chmod 666 "${CW_LOGDIR}/${CW_TOUCHFILE}"
else
    echo "ERROR while syncing files. Next run will try to sync again."
    rm -f "${CW_LOGDIR}/$CW_TOUCHFILE" 2>/dev/null
    exit 7
fi

# ----------------------------------------------------------------------
