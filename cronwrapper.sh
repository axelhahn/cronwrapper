#!/bin/bash
# ------------------------------------------------------------
#
# CRONWRAPPER
#
# ------------------------------------------------------------
# Was ist das hier?
# Es wird ein beliebiges Skript aufgerufen. Anhand des
# Die gesamte Ausgabe erfolgt in einer vorgegebenen Syntax,
# was das Parsen der Ausgabe vereinfacht
#
# Fuer MPC:
# 1) die gesamte Ausgabe wird aut. in ein Logfile geschrieben
#    (s. $OUTFILE).
# 2) Cron soll immer nur auf einem Server laufen - ttl eingefuegt
#    Es wird ein Lockfile mit expire-Zeit geschrieben
#
# Aufruf:
# {Skriptname} [ttl] [aufzurufendes Skript] [Bezeichner]
#   ttl: aufruf-Rhytmus dieses Skripts im Cron - in Minuten
#   Skript: Skript mit komplettem Pfad
#   Bezeichner: optional
#
# ------------------------------------------------------------
# 2002-02-06  ahahn  V1.0
# 2002-07-15         Stderr wird auch ins Logfile geschrieben
# 2002-09-17  ahahn  Email wird versendet, wenn Skript nicht
#                    ausführbar ist.
# 2003-04-05  ahahn  show output of executed script
# 2004-03-26  ahahn  added output with labels 2 grab infos from output
# 2006-01-01  ahahn  disabled email
# 2009-05-01  ahahn  MPC: keinerlei Ausgabe auf stdout- Ausgabe nur im Log
# 2009-05-04  ahahn  Test auf execute Rechte deaktiviert
# 2009-05-13  ahahn  Check: Cron darf nur einmalig auf einem Server laufen
#                    Dies erfordert Umstellung der Parameter-Struktur
# 2009-05-14  ahahn  sleep eingebaut mit Hilfe what_am_i
# 2009-05-18  ahahn  mehr Infos zu Locking und ausfuehrendem Server im Output
# 2010-10-19  ahahn  add JOBEXPIRE to output (to detect outdated cronjobs)
# 2012-04-03  ahahn  Sourcen von $0.cfg fuer eigene Variablenwerte
# 2012-04-04  ahahn  aktiver Job verwendet separates Logfile
# 2012-04-05  ahahn  TTL mit in der Ausgabe
# 2012-04-13  ahahn  joblog hinzugefuegt
# 2013-05-15  axel.hahn@iml.unibe.ch  FIRST IML VERSION
# 2013-07-xx  axel.hahn@iml.unibe.ch  TTL ist max 1h TTL-Parameter-Wert
# 2013-08-07  axel.hahn@iml.unibe.ch  Strip html in der Ausgabe
# 2017-10-13  axel.hahn@iml.unibe.ch  use eval to execute multiple commands
# 2021-02-23  ahahn  add help and parameter detection
# 2021-10-07  ahahn  use hostname with param -f
# ------------------------------------------------------------

# show help
# param  string  info or error message
function showhelp(){
echo "
$line1

AXELS CRONWRAPPER
Puts control and comfort to cronjobs.

source: https://github.com/axelhahn/cronwrapper
license: GNU GPL 3.0

$line1

$1


SYNTAX: $0 TTL COMMAND [LABEL]

PARAMETERS:
    TTL       integer value in [min]
              This value how often your cronjob runs. It is used to verify
              if a cronjob is out of date / does not run anymore.

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
You can run `dirname $0`/cronstatus.sh to get a list of all cronjobs and its
status. Check its source. Based on its logic you can create a check script for
your server monitoring.
"
}

# helper function - writes everything to file
function w() {
        echo $* >>$OUTFILE
}

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------
# allg. Konfiguration laden
# . `dirname $0`/config_allgemein.sh
line1="--------------------------------------------------------------------------------"

typeset -i TTL=$1 2>/dev/null
CALLSCRIPT=$2
LABELSTR=$3
LOGFILE=/tmp/call_any_script_$$.log

if [ "${LABELSTR}" = "" ]; then
        LABELSTR=`basename "${CALLSCRIPT}" | cut -f 1 -d " " `
fi
# Label darf keine Unterstriche enthalten
LABELSTR=`echo ${LABELSTR} | sed "s#_#-#g"`
TOUCHPART="_flag-${LABELSTR}_expire_"

LOGDIR="/var/tmp/cronlogs"
# WHATAMI=/data/srdrs/admin/bin/what_am_i
JOBBLOGBASE=`hostname`_joblog_

# . $0.cfg

FINALOUTFILE="$LOGDIR/`hostname -f`_${LABELSTR}.log"
JOBLOG="$LOGDIR/${JOBBLOGBASE}`date +%a`.done"
# OUTFILE="$LOGDIR/`hostname`_${LABELSTR}.log"
OUTFILE="$FINALOUTFILE.running"
typeset -i iStart=`date +%s`

# ------------------------------------------------------------
# CHECK PARAMS
# ------------------------------------------------------------
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]; then
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

# ------------------------------------------------------------
# WRITE HEADER
# ------------------------------------------------------------
mkdir $LOGDIR 2>/dev/null
chmod 777 $LOGDIR 2>/dev/null
rm -f $OUTFILE 2>/dev/null
touch $OUTFILE
w REM $line1
w REM CRON WRAPPER - `hostname`
# w REM `$WHATAMI`
w REM $line1

w "SCRIPTNAME=${CALLSCRIPT}"
w "SCRIPTTTL=${TTL}"
w "SCRIPTSTARTTIME=`date \"+%Y-%m-%d %H:%M:%S\"`, $iStart"
w "SCRIPTLABEL=${LABELSTR}"

if [ -z "${CALLSCRIPT}" ]; then
        w REM STOP: no script was found. check syntax for `basename $0`
        exit 1
fi
# ------------------------------------------------------------
# entspr. Nummer im Service warten;
# z.B. author-01 wartet 0 sec; author-02 wartet 1 sec
# ------------------------------------------------------------
# typeset -i sleep=`$WHATAMI | head -1 | sed "s#[a-zA-Z :]##g" | sed "s#--##g" | cut -f 2 -d "-"`-1
# if [ $sleep -lt 0 ]; then
#         sleep=0
# fi
#
# w REM sleep $sleep sec
# sleep $sleep


# ------------------------------------------------------------
# CHECK: runs this job on another machine?
# ------------------------------------------------------------
w REM $line1
# w REM check: runs this job on another machine?
typeset -i iExpire=`date +%s`
typeset -i iExpDelta=$TTL*3/2
if [ $iExpDelta -gt 60 ]; then
        iExpDelta=60
fi

# let iExpire=$iExpire+$TTL*60*3/2
let iExpire=$iExpire+$TTL*60+$iExpDelta*60
if [ $TTL -eq 0 ]; then
        iExpire=0
fi

lastfile=${LOGDIR}/*${TOUCHPART}*
ls $lastfile>/dev/null 2>&1
if [ $? -eq 0 ]; then
        TOUCHFILE=`basename $lastfile`
        typeset -i expdate=`echo $TOUCHFILE| cut -f 4 -d "_"` 2>/dev/null
        runserver=`echo $TOUCHFILE| cut -f 5 -d "_"`

        w REM INFO: expires $expdate - `date -d @$expdate`
        typeset -i timeleft=$expdate-$iStart
        w REM INFO: job is locked for other servers for $timeleft more seconds
        hostname | fgrep $runserver >/dev/null
        if [ $? -ne 0 ]; then
                w REM INFO: it locked up to $expdate by $runserver
                if [ $timeleft -gt 0 ]; then
                        w REM STOP: job is locked.
            mv $OUTFILE ${FINALOUTFILE}
                        exit 2
                else
                        w REM INFO: OK, job is expired
                fi
        else
                w REM INFO: job was executed on the same machine and can be executed here again.
        fi
else
        w REM OK, executing job the first time
fi

# -- delete all touchfiles of this job
rm -f ${LOGDIR}/*${TOUCHPART}* 2>/dev/null

# -- create touchfile for this server
touch "${LOGDIR}/${TOUCHPART}${iExpire}_`hostname`"
w JOBEXPIRE=${iExpire}
# w REM INFO: created touchfile ${TOUCHPART}${iExpire}_`hostname`
w REM $line1

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------
rc=none
RETSTATUS="OK"
eval ${CALLSCRIPT} >"${LOGFILE}" 2>&1
rc=$?
if [ $rc -ne 0 ]; then
        RETSTATUS="WARNING !!!"
fi


typeset -i iEnd=`date +%s`
w "SCRIPTENDTIME=`date \"+%Y-%m-%d %H:%M:%S\"`, $iEnd"
let iExectime=$iEnd-$iStart
w SCRIPTEXECTIME=$iExectime s

w SCRIPTRC=$rc

# w "sending email..."
# cat "${LOGFILE}" | mail -s"${EMAIL_SUBJECT} - ${LABELSTR} - $RETSTATUS" "${EMAIL_TO}"
# w "   rc=$?"
w "REM $line1"

cat "${LOGFILE}" | sed -e 's/<[^>]*>//g' | sed "s#^#SCRIPTOUT=#g" >>$OUTFILE
w "REM $line1"

# write a log for execution of a cronjob
echo "job=${LABELSTR}:host=`hostname`:start=$iStart:end=$iEnd:exectime=$iExectime:ttl=${TTL}:rc=$rc" >>$JOBLOG
chmod 777 $JOBLOG 2>/dev/null
find $LOGDIR -name "${JOBBLOGBASE}*" -type f -mtime +4 -exec rm -f {} \;

# ------------------------------------------------------------
# CLEANUP UND ENDE
# ------------------------------------------------------------
rm -f "${LOGFILE}"
w "REM $0 finished at `date`"
mv $OUTFILE ${FINALOUTFILE}

# ------------------------------------------------------------
# EOF
# ------------------------------------------------------------
