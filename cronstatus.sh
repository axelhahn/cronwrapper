#!/bin/bash
# ------------------------------------------------------------
#
# CRONWRAPPER :: STATUS
#
# Show status for all cronjobs using the cronwrapper
#
# ------------------------------------------------------------
# 2022-01-12  ahahn  1.1  fixes based on shellcheck
# 2022-03-09  ahahn  1.2  added cw.* functions
# 2022-09-21  ahahn  1.3  added colored OK or ERROR texts
# 2022-09-22  ahahn  1.4  add last output lines; add total status; exitstatus > 0 on error 
# 2022-10-27  ahahn  1.5  add 2 checks for hostname: is it a fqdn + filename matches hostname -f
# 2023-01-31  ahahn  1.6  add param support; analyze a single log
# 2023-05-22  ahahn  1.7  show running jobs
# 2023-07-14  ahahn  1.8  add support for REQUIREFQDN
# 2023-07-14  ahahn  1.9  added check if process still runs
# 2024-01-04  ahahn  1.10 update error messages
# 2024-01-30  ahahn  2.0  update help; use cw.emoji; use label as parameter; show last executions
# ------------------------------------------------------------

_version=2.0pre

CW_LABELSTR=
CW_LOGFILE=
LOGDIR=/var/tmp/cronlogs

typeset -i REQUIREFQDN=0
# outfile=/tmp/cronjob_status.$$.tmp
# outfile=/tmp/cronjob_status.tmp

test -f $( dirname $0)/cronwrapper.cfg && . $( dirname $0)/cronwrapper.cfg
. $( dirname $0)/inc_cronfunctions.sh

typeset -i iMaxAge
iMaxAge=$(date +%s)
typeset -i iErrJobs=0

statusOK=$(cw.color ok ; echo -n "OK"; cw.color reset)
statusERROR=$(cw.color error ; echo -n "ERROR"; cw.color reset)
sPre="    "

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

# get a value from logfile (everything behind "=")
# param: label
# global: $CW_LOGFILE
function getLogValue(){
        grep "^$1=" "$CW_LOGFILE" | cut -f 2- -d "="
}

# get logfiles of all cronwrapper cronjobs
function getLogfiles(){
        ls -1t "$LOGDIR"/*log | grep -Fv "/__"        
}

# get logfiles of all cronwrapper cronjobs
function _getLabel(){
        echo "$1" | rev | cut -f 1- -d '/' | rev | cut -f 2- -d '_' | sed "s,\.log.*,," 
}

# get logfiles of all cronwrapper cronjobs
function getRunningfiles(){
        ls -1t "$LOGDIR"/*log.running* 2>/dev/null
}

# show help
# param  string  info or error message
function showhelp(){
        local _self="$( basename $0 )"
echo "

Show the status of all local cronjobs that use the cronwrapper or a single job
by giving its logfile as parameter.

..... $( cw.emoji "✨" )SYNTAX:

  $_self [OPTIONS|LOGFILE]


..... $( cw.emoji "🔧" )OPTIONS:

  -h       show this help and exit.


..... $( cw.emoji "🏷️" )PARAMETERS:

  LOGFILE  filename to show details of a single logfile
           Default: without any logfile you get a total overview of all 
           cronjobs.


..... $( cw.emoji "🧩" )EXAMPLES:

  $_self
           show total overview over all jobs

  $_self $LOGDIR/myjobfile.log
           show output of a single job
"
}

# show last executions of the same job in the last few days (*done files)
# param  string  label
function _showLast(){
        local _label="$1"

        local iStart
        local iRc
        local iExectime
        local ico

        if grep "job=${_label}:" $CW_LOGDIR/*done >/dev/null; then
                echo
                echo "${sPre}Last executions within the last few days:"
                echo
                echo "${sPre}${sPre}    Start time           rc  Execution time"
                echo "${sPre}${sPre}    ------------------- --- ---------------"
                grep "job=${_label}:" $CW_LOGDIR/*done \
                        | tr ":" " " \
                        | sort -k +5 | tail -10 \
                        | while read -r line
                do
                        iStart=$(    echo "$line" | grep -o "start=[0-9]*"    | cut -f 2 -d "=")
                        iExectime=$( echo "$line" | grep -o "exectime=[0-9]*" | cut -f 2 -d "=")
                        iRc=$(       echo "$line" | grep -o "rc=[0-9]*"       | cut -f 2 -d "=")
                        # echo "    $line"

                        ico=
                        test "$iRc" = "0" && ico=$( cw.emoji "✔️" )
                        test "$iRc" = "0" || ico=$( cw.emoji "❌" )
                        printf "${sPre}${sPre}%3s %19s %3s   %10s s\n" "$ico" "$( date +%Y-%m-%d\ %H:%M:%S --date=@$iStart )" "$iRc" "$iExectime"
                done
        fi
} 

# show status of a single sob
# param  string  filename of cronwrapper logfile OR label of cronjob
# param  bool    flag: show logfile content; default: empty (=do not sohow log)
function showStatus(){
        local _label="$1"
        test -f "$_label" && CW_LOGFILE="$_label"
        test -f "$_label" || CW_LOGFILE="$CW_LOGDIR/$( hostname -f )_${_label}.log"

        CW_LABELSTR=$( _getLabel "$CW_LOGFILE")
        local _showlog="$2"
        echo
        cw.cecho "head" "..... $( cw.emoji "📜" )$CW_LABELSTR"
        echo
        echo "    Logfile   : $CW_LOGFILE"
        if [ -n "$_showlog" ]; then
                cat "$CW_LOGFILE" \
                        | sed -e "s/^REM.*/$( printf "\033[0;36m&\033[0m" )/g" \
                                -e "s/^[A-Z]*/$( printf "\033[0;35m&\033[0m" )/g" \
                                -e "s/=/$( printf "\033[0;32m&\033[0m" )/g" \
                                -e "s/----- HOOK.*$/$( printf "\033[0;36m&\033[0m" )/g" \
                                -e "s/^/    /g"
                echo
                echo "    Logfile   : $CW_LOGFILE"
        fi
        typeset -i iErr=0

        # server=$(basename "$CW_LOGFILE" | cut -f 1 -d "_")
        # jobname=$(basename "$CW_LOGFILE" | cut -f 2 -d "_" | sed "s#\.log##")

        sCmd=$(getLogValue SCRIPTNAME)
        sLastStart=$(getLogValue SCRIPTSTARTTIME)
        typeset -i iJobExpire
        iJobExpire=$(getLogValue JOBEXPIRE)
        typeset -i rc
        rc=$(getLogValue 'SCRIPTRC' | head -1)
        typeset -i iExectime
        iExectime=$(getLogValue 'SCRIPTEXECTIME' | head -1 | cut -f 1 -d " ")
        # remark: other execution times of the same job
        # grep "=JOBNAME:" /var/tmp/cronlogs/*joblog*

        sTTL=$(getLogValue 'SCRIPTTTL')

        # ----- check return code
        sServer=$(basename "$CW_LOGFILE" | cut -f 1 -d "_")
        sFqdnCheck=
        sServerCheck=

        if test "$REQUIREFQDN" != "0" && ! echo "$sServer" | grep "\." >/dev/null; then
                sFqdnCheck="WARNING   : No FQDN in filename - only the short hostname: [$sServer]"
                iErr+=1
        fi
        if test "${sCurrentServer}" != "$sServer"; then
                sServerCheck="WARNING   : hostname -f returns [${sCurrentServer}] ... and differs to [$sServer] from CW_LOGFILE."
                iErr+=1
        fi

        # ----- check return code
        statusRc="${statusOK}"
        if [ $rc -ne 0 ]; then
                iErr+=1
                statusRc="<<<<<<<<<< ${statusERROR}: non zero exit code"
        fi

        # ----- check ttl value
        typeset -i iTTL=$sTTL
        typeset -i iTTLsec=0
        
        iTTLsec=$(( iTTL*60 ))
        # ttlstatus="OK"
        if [ -z "$sTTL" ]; then
                iErr+=1
                statusTtl="${statusERROR}: ttl value is empty"
        else
                # human readable ttl in min/ hours/ days
                statusTtl="$iTTL min"
                if [ $iTTL -gt 60 ]; then
                        iTTL=$iTTL/60;
                        statusTtl="$sTTL - $iTTL h"
                        if [ $iTTL -gt 24 ]; then
                                iTTL=$iTTL/24;
                                statusTtl="$sTTL - $iTTL d"
                        fi
                fi
                if [ $iTTLsec -lt $iExectime ]; then
                        iErr=$iErr+1
                        statusTtl="${statusERROR}: $iTTL min = $iTTLsec s - is too low; exec time is $iExectime s - set a higher TTL for this cronjob"
                        iErr+=1
                else
                        statusTtl="$statusTtl ${statusOK}"
                fi
        fi
        # ----- check expire
        statusExpire="$(date -d @$iJobExpire '+%Y-%m-%d %H:%M:%S')"
        if [ $iJobExpire -lt $iMaxAge ]; then
                statusExpire="${statusExpire} <<<<<<<<<< ${statusERROR}: Expired"
                iErr+=1
        else
                statusExpire="${statusExpire} ${statusOK}"
        fi

        # ----- OUTPUT

        echo "${sPre}command   : ${sCmd}"
        echo "${sPre}last start: ${sLastStart}"
        echo "${sPre}returncode: ${rc} ${statusRc}"
        if [ $rc -ne 0 ]; then
                echo
                echo "${sPre}${sPre}Last lines in output:"
                getLogValue SCRIPTOUT | tail -20 | sed "s#^#${sPre}${sPre}#g"
                echo
        fi
        echo "${sPre}duration  : ${iExectime} s"
        echo "${sPre}ttl       : ${statusTtl}"
        echo "${sPre}expires   : ${iJobExpire} ${statusExpire}"
        test -n "${sFqdnCheck}"   && cw.cecho "warning" "${sPre}${sFqdnCheck}"
        test -n "${sServerCheck}" && cw.cecho "warning" "${sPre}${sServerCheck}"


        if [ $iErr -gt 0 ]; then
                cw.cecho "error" "${sPre}$( cw.emoji "❌" )CHECK FAILED"
                iErrJobs=$iErrJobs+1
        else
                cw.cecho "ok" "${sPre}$( cw.emoji "✔️" )CHECK OK"
        fi
        _showLast "$CW_LABELSTR"
        echo
}

# show running jobs
function showRunningJobs(){
        local sCmd
        local sLastStart
        local iSince
        local iTTL
        local iPid
        if getRunningfiles >/dev/null 2>&1 ; then
                echo "____________________________________________________________________________________"
                echo
                echo "CURRENTLY RUNNING JOBS:"

                for CW_LOGFILE in $( getRunningfiles )
                do
                        CW_LABELSTR=$( _getLabel "$CW_LOGFILE")
                        sCmd=$(getLogValue SCRIPTNAME)
                        sLastStart=$(getLogValue SCRIPTSTARTTIME)
                        typeset -i iSince; iSince=($( date '+%s' )-$( echo "$sLastStart" | cut -f 2 -d ',' ))/60
                        typeset -i iTTL;   iTTL=$(getLogValue 'SCRIPTTTL')
                        if [ $iTTL -lt $iSince ]; then
                                statusTtl="${statusERROR}: TTL=$iTTL min is lower than execution time of ${iSince} min"
                                iErr+=1
                        fi

                        echo
                        cw.cecho "head" "${sPre}..... $( cw.emoji "⏳" )for $iSince min - $CW_LABELSTR"
                        echo
                        echo "${sPre}${sPre}Logfile   : $CW_LOGFILE"
                        typeset -i iPid; iPid=$(getLogValue SCRIPTPROCESS)
                        if [ $iPid -gt 0 ]; then
                                # detect process id and check if it is still running
                                if ps $iPid >/dev/null 2>&1; then
                                        cw.cecho "ok" "${sPre}${sPre}OK - still running"
                                else
                                        cw.cecho "error" "${sPre}${sPre}ERROR     : The process $iPid does not exist anymore. The job was aborted."
                                        cw.cecho "error" "${sPre}${sPre}            Check the log file and delete it."
                                        iErr+=1
                                fi
                        fi

                        echo "${sPre}${sPre}command   : ${sCmd}"
                        echo "${sPre}${sPre}last start: ${sLastStart}"
                        echo "${sPre}${sPre}ttl       : ${iTTL} min"
                        echo
                done
        else
                echo
                echo "There is no running job."
        fi
}

# show total overview of all jobs
function showTotalstatus(){
        for logfile in $( getLogfiles )
        do
                showStatus "$logfile"
        done

        showRunningJobs

        echo "____________________________________________________________________________________"

        echo "JOBS: $(getLogfiles | wc -l ) .. RUNNING: $(getRunningfiles | wc -l ) .. ERRORS: $iErrJobs"
        echo
}
# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

sCurrentServer=$(hostname -f)
cat <<ENDOFHEAD
____________________________________________________________________________________

  AXELS CRONWRAPPER - Jobstatus of cronjobs on $( cw.emoji "🖥️" )$( hostname -f )
_____________________________________________________________________________/ v$_version
ENDOFHEAD

if [ "$1" = "-h" ]; then
        showhelp
        exit 0
fi

if [ -n "$1" ]; then
        showStatus "$1" 1
        echo
else
        showTotalstatus
fi
exit $iErrJobs

# ----------------------------------------------------------------------
