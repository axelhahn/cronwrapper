#!/bin/bash
# ------------------------------------------------------------
#
# AXELS CRONWRAPPER
#
# ------------------------------------------------------------
#
# Call any command in a cronjob and write a parsable log.
#
# SYNTAX: SYNTAX: $0 TTL COMMAND [LABEL]
# Start script without parameters to see the help or have a
# to the ./docs/ directory.
#
# ------------------------------------------------------------
# 2002-02-06  ahahn  V1.0
# 2002-07-15         1.1   Stderr wird auch ins CW_LOGFILE geschrieben
# 2002-09-17  ahahn  1.2   Email wird versendet, wenn Skript nicht
#                          ausfuehrbar ist.
# 2003-04-05  ahahn  1.3   show output of executed script
# 2004-03-26  ahahn  1.4   added output with labels 2 grab infos from output
# 2006-01-01  ahahn  1.5   disabled email
# 2009-05-01  ahahn  1.6   MPC: keinerlei Ausgabe auf stdout- Ausgabe nur im Log
# 2009-05-04  ahahn  1.7   Test auf execute Rechte deaktiviert
# 2009-05-13  ahahn  1.8   Check: Cron darf nur einmalig auf einem Server laufen
#                          Dies erfordert Umstellung der Parameter-Struktur
# 2009-05-14  ahahn  1.9   sleep eingebaut mit Hilfe what_am_i
# 2009-05-18  ahahn  1.10  mehr Infos zu Locking und ausfuehrendem Server im Output
# 2010-10-19  ahahn  1.11  add JOBEXPIRE to output (to detect outdated cronjobs)
# 2012-04-03  ahahn  1.12  Sourcen von $0.cfg fuer eigene Variablenwerte
# 2012-04-04  ahahn  1.13  aktiver Job verwendet separates CW_LOGFILE
# 2012-04-05  ahahn  1.14  TTL mit in der Ausgabe
# 2012-04-13  ahahn  1.15  joblog hinzugefuegt
# 2013-05-15  axel.hahn@iml.unibe.ch  1.16  FIRST IML VERSION
# 2013-07-xx  axel.hahn@iml.unibe.ch  1.17  TTL ist max 1h TTL-Parameter-Wert
# 2013-08-07  axel.hahn@iml.unibe.ch  1.18  Strip html in der Ausgabe
# 2017-10-13  axel.hahn@iml.unibe.ch  1.19  use eval to execute multiple commands
# 2021-02-23  ahahn  1.20  add help and parameter detection
# 2022-01-12  ahahn  1.21  fixes based on shellcheck
# 2022-01-14  ahahn  1.22  fix CW_RUNSERVER check
# 2022-03-09  ahahn  1.23  small changes
# 2022-07-14  ahahn  1.24  added: deny multiple execution of the same job
# 2022-07-16  ahahn  1.25  FIX: outfile of running job is a uniq file
# 2022-07-16  ahahn  1.26  FIX: singlejob option was broken in 1.25
# 2024-01-23  ahahn  WIP   add hooks; update help; use cw.emoji
# 2024-04-03  ahahn  2.0   update bashdoc
# ------------------------------------------------------------

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

_version="2.0"
line1="------------------------------------------------------------------------------"

. "$( dirname "$0")/inc_cronfunctions.sh"

# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

# helper script: detect the current script path evn if it is a softlink
# return: path of the script
# No parameters needed
function getRealScriptPath(){
  local _source;
  _source=${BASH_SOURCE[0]}
  while [ -L "$_source" ]; do # resolve $_source until the file is no longer a symlink
  CW_DIRSELF=$( cd -P "$( dirname "$_source" )" >/dev/null 2>&1 && pwd )
  _source=$(readlink "$_source")
  [[ $_source != /* ]] && _source=$CW_DIRSELF/$_source # if $_source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  cd -P "$( dirname "$_source" )" >/dev/null 2>&1 && pwd
}

# show help
# param  string  info or error message
# No parameters needed
#
# global  string  $_version    version of the script
# global  string  $CW_DIRSELF  directory of the script
# global s tring  $CW_LOGDIR   directory of the logfiles
function showhelp(){
        cw.color head
        cat <<ENDOFHEAD

                                                                           | 
    A  X  E  L  S                                                        --x--
   ______                        ________                                  |
  |      |.----.-----.-----.    |  |  |  |.----.---.-.-----.-----.-----.----.
  |   ---||   _|  _  |     |    |  |  |  ||   _|  _  |  _  |  _  |  -__|   _|
  |______||__| |_____|__|__|    |________||__| |___._|   __|   __|_____|__|  
                                                     |__|  |__|
$( printf "%76s" "v $_version" )
ENDOFHEAD
cw.color reset
cat <<ENDOFHELP


  Puts control and comfort to your cronjobs.

  $( cw.emoji "📄" )Source : https://github.com/axelhahn/cronwrapper
  $( cw.emoji "📜" )License: GNU GPL 3.0
  $( cw.emoji "📗" )Docs   : https://www.axel-hahn.de/docs/cronwrapper/

$(test -n "$1" && ( cw.color error; echo "$1"; cw.color reset; echo; echo ))
$(cw.helpsection "✨" "SYNTAX")

  $0 TTL COMMAND [LABEL]

$(cw.helpsection "🏷️" "PRAMETERS")

  TTL     integer value in [min]
          This value says how often your cronjob runs. It is used to verify
          if a cronjob is out of date / does not run anymore.
          As a fast help a few values:
            60    - 1 hour
            1440  - 1 day
            10080 - 7 days
  
  COMMAND command to execute
          When using spaces or parameters then quote it.
          Be strict: if your job is ok then exit wit returncode 0.
          If an error occurs exit with returncode <> 0.
  
  LABEL   optional: label to be used as output filename
          If not set it will be detected from basename of executed command.
          When you start a script with different parameters it is highly
          recommended to set the label.

$(cw.helpsection "📝" "REMARK")

  You don't need to redirect the output in a cron config file. STDOUT and
  STDERR will be fetched automaticly. 
  It also means: Generate as much output as you want and want to have to debug
  a job in error cases.

$(cw.helpsection "🗨️" "MORE TO SAY")

  The output directory of all jobs executed by $0 is
  ${CW_LOGDIR}.
  The output logs are parseble with simple grep command.

  You can run $( cw.cecho cmd $CW_DIRSELF/cronstatus.sh ) to get a list of all cronjobs and 
  its status. Based on its output you can create a check script for your 
  server monitoring.

  You can sync all logfiles of all cronjobs to a defined server using
  $( cw.cecho cmd $CW_DIRSELF/cronlog-sync.sh )
  
ENDOFHELP
}

# helper function - append a line to output file
#
# global  string  $CW_OUTFILE  output file of the current job
#
# param   string  text to write
function w() {
        echo "$*" >>"$CW_OUTFILE"
}

# execute hook skripts in a given directory in alphabetic order
#
# global  string   $CW_HOOKDIR  directory of the hook scripts
#
# param   string   name of hook directory
# param   string   optional: integer of existcode or "" for non-on-result hook
function runHooks(){
        local _hookbase="$1"
        local _exitcode="$2"
        local _hookdir; _hookdir="${CW_HOOKDIR}/$_hookbase"

        if [ -z "$_exitcode" ]; then
                _hookdir="$_hookdir/always"
        elif [ "$_exitcode" = "0" ]; then
                _hookdir="$_hookdir/on-ok"
        else
                _hookdir="$_hookdir/on-error"
        fi
        for hookscript in $( ls -1a "$_hookdir" | grep -v "^\." | sort )
        do
                if [ -x "$_hookdir/$hookscript" ]; then
                        echo "----- HOOK START: $_hookdir/$hookscript"
                        "$_hookdir/$hookscript"
                        echo "----- HOOK END  : $_hookdir/$hookscript"
                        echo
                else
                        w "REM HOOK: SKIP $_hookdir/$hookscript (not executable)"
                fi
        done

        # if an exitcode was given as param then run hooks without exitcode 
        # (in subdir "always")
        if [ -n "$_exitcode" ]; then
                runHooks "$_hookbase"
        fi
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

# --- set vars with required cli params
typeset -i TTL=$1 2>/dev/null
CW_CALLSCRIPT=$2
CW_LABELSTR=$3

test -z "${CW_LABELSTR}" && CW_LABELSTR=$(basename "${CW_CALLSCRIPT}" | cut -f 1 -d " " )

CW_DIRSELF=$( getRealScriptPath )

# replace underscore (because it is used as a delimiter)
CW_LABELSTR=${CW_LABELSTR//_/-}
CW_TOUCHPART="_flag-${CW_LABELSTR}_expire_"

CW_LOGFILE=/tmp/call_any_script_$$.log
CW_LOGDIR="/var/tmp/cronlogs"
CW_HOOKDIR=${CW_DIRSELF}/hooks
CW_KEEPDAYS=14
CW_MYHOST=$( hostname -f )

# --- log executions of the whole day
CW_JOBBLOGBASE=${CW_MYHOST}_joblog_
CW_SINGLEJOB=1


test -f "${CW_DIRSELF}/cronwrapper.env" && . "${CW_DIRSELF}/cronwrapper.env"
test -f "${CW_DIRSELF}/cronwrapper.cfg" && . "${CW_DIRSELF}/cronwrapper.cfg"
. "${CW_DIRSELF}/inc_cronfunctions.sh"

CW_HOOKDIR=${CW_HOOKDIR/./$( dirname $0 )}
CW_FINALOUTFILE="$CW_LOGDIR/${CW_MYHOST}_${CW_LABELSTR}.log"
CW_JOBLOG="$CW_LOGDIR/${CW_JOBBLOGBASE}$(date +%Y%m%d-%a).done"
CW_OUTFILEBASE="$CW_FINALOUTFILE.running"
CW_OUTFILE="$CW_OUTFILEBASE.$$"

typeset -i CW_TIMER_START
CW_TIMER_START=$(date +%s)

# ------------------------------------------------------------
# CHECK PARAMS
# ------------------------------------------------------------
if [ "$1" = "-?" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	showhelp
	exit 1
fi
if [ $# -lt 2 ]; then
	showhelp "ERROR: missing parameters."
	exit 1
fi
if [ $TTL -eq 0 ]; then
	showhelp "ERROR: TTL must be integer and greater zero."
	exit 1
fi
if [ -z "${CW_MYHOST}" ]; then
	showhelp "ERROR: hostname -f did not return any hostname."
	exit 1
fi

test -d $CW_LOGDIR || mkdir $CW_LOGDIR 2>/dev/null
chmod 777 $CW_LOGDIR 2>/dev/null

# ------------------------------------------------------------
# prevent multiple execution ... if configured
# ------------------------------------------------------------
if [ "$CW_SINGLEJOB" != "0" ]; then
        for otheroutfile in $( ls -1 $CW_OUTFILEBASE.* 2>/dev/null )
        do
                typeset -i runningProcessid; 
                runningProcessid=$(grep "SCRIPTPROCESS" "$otheroutfile" | cut -f 2 -d '=')
                if [ $runningProcessid -gt 0 ]; then
                        if ps $runningProcessid >/dev/null; then
                                echo "job=${CW_LABELSTR}:host=$CW_MYHOST:start=$CW_TIMER_START:end=$CW_TIMER_START:exectime=0:ttl=${TTL}:rc=1:blockingpid=$runningProcessid" >>"$CW_JOBLOG"
                                exit 1
                        fi
                fi
        done
fi

# ------------------------------------------------------------
# WRITE HEADER
# ------------------------------------------------------------
w "REM $line1"
w "REM CRON WRAPPER - $CW_MYHOST"
w "REM $line1"

w "SCRIPTNAME=${CW_CALLSCRIPT}"
w "SCRIPTTTL=${TTL}"
w "SCRIPTSTARTTIME=$( date '+%Y-%m-%d %H:%M:%S' ), $CW_TIMER_START"
w "SCRIPTLABEL=${CW_LABELSTR}"
w "SCRIPTPROCESS=$$"

if [ -z "${CW_CALLSCRIPT}" ]; then
        w "REM STOP: no script was found. check syntax for $(basename $0)"
        exit 1
fi

# ------------------------------------------------------------
# CHECK: runs this job on another machine?
# ------------------------------------------------------------
w REM $line1
typeset -i CW_TIMER_EXPIRE
CW_TIMER_EXPIRE=$(date +%s)
typeset -i CW_TIMER_EXPIREDELTA=$(( TTL*3/2 ))
if [ $CW_TIMER_EXPIREDELTA -gt 60 ]; then
        CW_TIMER_EXPIREDELTA=60
fi

# let CW_TIMER_EXPIRE=$CW_TIMER_EXPIRE+$TTL*60*3/2
CW_TIMER_EXPIRE=$(( CW_TIMER_EXPIRE+TTL*60 + CW_TIMER_EXPIREDELTA*60 ))
if [ $TTL -eq 0 ]; then
        CW_TIMER_EXPIRE=0
fi

CW_ARR_RUNFILES=( "${CW_LOGDIR}"/*"${CW_TOUCHPART}"* )
CW_LASTFILE=${CW_ARR_RUNFILES[0]}

if ls "${CW_LASTFILE}" >/dev/null 2>&1; then
        CW_TOUCHFILE=$(basename "$CW_LASTFILE")
        typeset -i CW_TIMER_EXPDATE
        CW_TIMER_EXPDATE=$(echo "$CW_TOUCHFILE"| cut -f 4 -d "_") 2>/dev/null
        CW_RUNSERVER=$(echo "$CW_TOUCHFILE" | cut -f 5 -d "_")

        w "REM INFO: expires $CW_TIMER_EXPDATE - $(date -d @$CW_TIMER_EXPDATE)"
        typeset -i CW_TIMER_TIMELEFT=$CW_TIMER_EXPDATE-$CW_TIMER_START
        # w "REM INFO: job is locked for other servers for $CW_TIMER_TIMELEFT more seconds"
        if ! echo "${CW_MYHOST}" | grep -F "$CW_RUNSERVER" >/dev/null; then
                w "REM INFO: it locked up to $CW_TIMER_EXPDATE by $CW_RUNSERVER"
                if [ $CW_TIMER_TIMELEFT -gt 0 ]; then
                        w REM STOP: job is locked.
                        mv "$CW_OUTFILE" "${CW_FINALOUTFILE}"
                        exit 2
                else
                        w REM INFO: OK, job is expired
                fi
        # else
        #        w REM INFO: job was executed on the same machine before.
        fi
else
        w REM OK, executing job the first time
fi

# -- delete all touchfiles of this job
rm -f "${CW_LOGDIR}"/*"${CW_TOUCHPART}"* 2>/dev/null

# -- create touchfile for this server
touch "${CW_LOGDIR}/${CW_TOUCHPART}${CW_TIMER_EXPIRE}_${CW_MYHOST}"
w JOBEXPIRE=${CW_TIMER_EXPIRE}
# w REM INFO: created touchfile ${CW_TOUCHPART}${CW_TIMER_EXPIRE}_`hostname`
w REM $line1

# ------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------
rc=none

runHooks "before"       > "${CW_LOGFILE}" 2>&1
eval "${CW_CALLSCRIPT}" >>"${CW_LOGFILE}" 2>&1
rc=$?
typeset -i CW_TIMER_END
CW_TIMER_END=$(date +%s)
w "SCRIPTENDTIME=$( date '+%Y-%m-%d %H:%M:%S' ), $CW_TIMER_END"
iExectime=$(( CW_TIMER_END-CW_TIMER_START ))
w SCRIPTEXECTIME=$iExectime s
w SCRIPTRC=$rc
w "REM $line1"


# write a log for execution of a cronjob
echo "job=${CW_LABELSTR}:host=$CW_MYHOST:start=$CW_TIMER_START:end=$CW_TIMER_END:exectime=$iExectime:ttl=${TTL}:rc=$rc" >>"$CW_JOBLOG"
chmod 777 "$CW_JOBLOG" 2>/dev/null
find $CW_LOGDIR -name "${CW_JOBBLOGBASE}*" -type f -mtime +$CW_KEEPDAYS -exec rm -f {} \;

runHooks "after" $rc >>"${CW_LOGFILE}" 2>&1

sed -e 's/<[^>]*>//g' "${CW_LOGFILE}" | sed "s#^#SCRIPTOUT=#g" >>"$CW_OUTFILE"
w "REM $line1"

# ------------------------------------------------------------
# CLEANUP AND END
# ------------------------------------------------------------
rm -f "${CW_LOGFILE}"
w "REM $0 finished at $(date)"
mv "${CW_OUTFILE}" "${CW_FINALOUTFILE}"

# ------------------------------------------------------------
# EOF
# ------------------------------------------------------------
