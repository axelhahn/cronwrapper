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
# 2002-07-15         1.1   Stderr wird auch ins Logfile geschrieben
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
# 2012-04-04  ahahn  1.13  aktiver Job verwendet separates Logfile
# 2012-04-05  ahahn  1.14  TTL mit in der Ausgabe
# 2012-04-13  ahahn  1.15  joblog hinzugefuegt
# 2013-05-15  axel.hahn@iml.unibe.ch  1.16  FIRST IML VERSION
# 2013-07-xx  axel.hahn@iml.unibe.ch  1.17  TTL ist max 1h TTL-Parameter-Wert
# 2013-08-07  axel.hahn@iml.unibe.ch  1.18  Strip html in der Ausgabe
# 2017-10-13  axel.hahn@iml.unibe.ch  1.19  use eval to execute multiple commands
# 2021-02-23  ahahn  1.20  add help and parameter detection
# 2022-01-12  ahahn  1.21  fixes based on shellcheck
# 2022-01-14  ahahn  1.22  fix runserver check
# 2022-03-09  ahahn  1.23  small changes
# 2022-07-14  ahahn  1.24  added: deny multiple execution of the same job
# ------------------------------------------------------------

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

_version="1.24"
line1="--------------------------------------------------------------------------------"

# --- set vars with required cli params
typeset -i TTL=$1 2>/dev/null
CALLSCRIPT=$2
LABELSTR=$3
LOGFILE=/tmp/call_any_script_$$.log

test -z "${LABELSTR}" && LABELSTR=$(basename "${CALLSCRIPT}" | cut -f 1 -d " " )

# replace underscore (because it is used as a delimiter)
# LABELSTR=$(echo ${LABELSTR} | sed "s#_#-#g")
LABELSTR=${LABELSTR//_/-}
TOUCHPART="_flag-${LABELSTR}_expire_"

LOGDIR="/var/tmp/cronlogs"
MYHOST=$( hostname -f )

# --- log executions of the whole day
JOBBLOGBASE=${MYHOST}_joblog_
SINGLEJOB=1

# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

# show help
# param  string  info or error message
function showhelp(){
echo "
$line1

AXELS CRONWRAPPER v $_version
Puts control and comfort to cronjobs.

source: https://github.com/axelhahn/cronwrapper
license: GNU GPL 3.0

$line1

$1

SYNTAX: $0 TTL COMMAND [LABEL]

PARAMETERS:
    TTL       integer value in [min]
              This value says how often your cronjob runs. It is used to verify
              if a cronjob is out of date / does not run anymore.
              As a fast help a few values:
                60   - 1 hour
                1440 - 1 day

    COMMAND   command to execute
              When using spaces or parameters then quote it.
              Be strict: if your job is ok then exit wit returncode 0.
              If an error occurs exit with returncode <> 0.

    LABEL     optional: label to be used as output filename
              If not set it will be detected from basename of executed command.
              When you start a script with different parameters it is highly
              recommended to set the label.

REMARK:
You don't need to redirect the output in a cron config file. STDOUT and
STDERR will be fetched automaticly. 
It also means: Generate as much output as you want and want to have to debug a
job in error cases.

OUTPUT:
The output directory of all jobs executed by $0 is
${LOGDIR}.
The output logs are parseble with simple grep command.

MONITORING:
You can run $(dirname $0)/cronstatus.sh to get a list of all cronjobs and its
status. Check its source. Based on its logic you can create a check script for
your server monitoring.
"
}

# helper function - append to file
function w() {
        echo "$*" >>"$OUTFILE"
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

test -f "$( dirname $0)/cronwrapper.env" && . $( dirname $0)/cronwrapper.env
test -f "$( dirname $0)/cronwrapper.cfg" && . $( dirname $0)/cronwrapper.cfg
. $( dirname $0)/inc_cronfunctions.sh


FINALOUTFILE="$LOGDIR/${MYHOST}_${LABELSTR}.log"
JOBLOG="$LOGDIR/${JOBBLOGBASE}$(date +%a).done"
# OUTFILE="$LOGDIR/`hostname`_${LABELSTR}.log"
OUTFILE="$FINALOUTFILE.running"
typeset -i iStart
iStart=$(date +%s)

# ------------------------------------------------------------
# CHECK PARAMS
# ------------------------------------------------------------
if [ "$1" = "-?" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	showhelp "Showing help ..."
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
if [ -z "${MYHOST}" ]; then
	showhelp "ERROR: hostname -f did not return any hostname."
	exit 1
fi

# ------------------------------------------------------------
# WRITE HEADER
# ------------------------------------------------------------
mkdir $LOGDIR 2>/dev/null
chmod 777 $LOGDIR 2>/dev/null

# prevent multiple execution
if test -f "$OUTFILE"; then
        typeset -i runningProcessid; 
        runningProcessid=$(grep "SCRIPTPROCESS" "$OUTFILE" | cut -f 2 -d '=')
        if [ $runningProcessid -gt 0 ]; then
                if ps $runningProcessid >/dev/null; then
                        # the last process is still running
                        if [ "$SINGLEJOB" != "0" ]; then
                                OUTFILE=$FINALOUTFILE
                                w "ERROR: Execution of the next task PID $$ at $( date ) was blocked."
                                echo "ERROR: The job is still running as PID $runningProcessid ... stopping the new task."
                                exit 1
                        fi
                fi
        fi
fi
rm -f "$OUTFILE" 2>/dev/null
touch "$OUTFILE"
w "REM $line1"
w "REM CRON WRAPPER - $MYHOST"
w "REM $line1"

w "SCRIPTNAME=${CALLSCRIPT}"
w "SCRIPTTTL=${TTL}"
w "SCRIPTSTARTTIME=$( date '+%Y-%m-%d %H:%M:%S' ), $iStart"
w "SCRIPTLABEL=${LABELSTR}"
w "SCRIPTPROCESS=$$"

if [ -z "${CALLSCRIPT}" ]; then
        w "REM STOP: no script was found. check syntax for $(basename $0)"
        exit 1
fi


# ------------------------------------------------------------
# CHECK: runs this job on another machine?
# ------------------------------------------------------------
w REM $line1
typeset -i iExpire
iExpire=$(date +%s)
typeset -i iExpDelta=$(( TTL*3/2 ))
if [ $iExpDelta -gt 60 ]; then
        iExpDelta=60
fi

# let iExpire=$iExpire+$TTL*60*3/2
iExpire=$(( iExpire+TTL*60 + iExpDelta*60 ))
if [ $TTL -eq 0 ]; then
        iExpire=0
fi

aLastfiles=( "${LOGDIR}"/*"${TOUCHPART}"* )
lastfile=${aLastfiles[0]}

if ls "${lastfile}" >/dev/null 2>&1; then
        TOUCHFILE=$(basename "$lastfile")
        typeset -i expdate
        expdate=$(echo "$TOUCHFILE"| cut -f 4 -d "_") 2>/dev/null
        runserver=$(echo "$TOUCHFILE" | cut -f 5 -d "_")

        w "REM INFO: expires $expdate - $(date -d @$expdate)"
        typeset -i timeleft=$expdate-$iStart
        # w "REM INFO: job is locked for other servers for $timeleft more seconds"
        if ! echo "${MYHOST}" | grep -F "$runserver" >/dev/null; then
                w "REM INFO: it locked up to $expdate by $runserver"
                if [ $timeleft -gt 0 ]; then
                        w REM STOP: job is locked.
                        mv "$OUTFILE" "${FINALOUTFILE}"
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
rm -f "${LOGDIR}"/*"${TOUCHPART}"* 2>/dev/null

# -- create touchfile for this server
touch "${LOGDIR}/${TOUCHPART}${iExpire}_${MYHOST}"
w JOBEXPIRE=${iExpire}
# w REM INFO: created touchfile ${TOUCHPART}${iExpire}_`hostname`
w REM $line1

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------
rc=none
# RETSTATUS="OK"
eval "${CALLSCRIPT}" >"${LOGFILE}" 2>&1
rc=$?
# if [ $rc -ne 0 ]; then
#         RETSTATUS="WARNING !!!"
# fi
# w "sending email..."
# cat "${LOGFILE}" | mail -s"${EMAIL_SUBJECT} - ${LABELSTR} - $RETSTATUS" "${EMAIL_TO}"
# w "   rc=$?"

typeset -i iEnd
iEnd=$(date +%s)
w "SCRIPTENDTIME=$( date '+%Y-%m-%d %H:%M:%S' ), $iEnd"
iExectime=$(( iEnd-iStart ))
w SCRIPTEXECTIME=$iExectime s

w SCRIPTRC=$rc


w "REM $line1"

sed -e 's/<[^>]*>//g' "${LOGFILE}" | sed "s#^#SCRIPTOUT=#g" >>"$OUTFILE"
w "REM $line1"

# write a log for execution of a cronjob
echo "job=${LABELSTR}:host=$MYHOST:start=$iStart:end=$iEnd:exectime=$iExectime:ttl=${TTL}:rc=$rc" >>"$JOBLOG"
chmod 777 "$JOBLOG" 2>/dev/null
find $LOGDIR -name "${JOBBLOGBASE}*" -type f -mtime +4 -exec rm -f {} \;

# ------------------------------------------------------------
# CLEANUP UND ENDE
# ------------------------------------------------------------
rm -f "${LOGFILE}"
w "REM $0 finished at $(date)"
mv "${OUTFILE}" "${FINALOUTFILE}"

# ------------------------------------------------------------
# EOF
# ------------------------------------------------------------
