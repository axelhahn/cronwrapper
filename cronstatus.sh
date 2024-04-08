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
# 2024-01-30  ahahn  WIP  update help; use cw.emoji; use label as parameter; show last executions
# 2024-04-03  ahahn  2.0  add CW_LOGDIR; update bashdoc
# 2024-04-04  ahahn  2.1  harden against bash pipefail option; added: skip intro header (-i)
# 2024-04-07  ahahn  2.2  update bash docs; define local vars
# 2024-04-08  ahahn  2.3  remove "set -eu -o pipefail"
# ------------------------------------------------------------

# set -eu -o pipefail

CW_LABELSTR=
CW_LOGFILE=
CW_LOGDIR=/var/tmp/cronlogs

typeset -i CW_REQUIREFQDN=0

test -f $( dirname $0)/cronwrapper.cfg && . $( dirname $0)/cronwrapper.cfg
. $( dirname $0)/inc_cronfunctions.sh || exit 1

_version="2.3"

typeset -i iMaxAge
iMaxAge=$(date +%s)
typeset -i iErrJobs=0

typeset -i bShowDetails=1
typeset -i bShowHistory=1
typeset -i bShowRunning=1
typeset -i bShowLogfile=1
typeset -i bShowHead=1

line1="______________________________________________________________________________"
statusOK=$(cw.cecho ok "OK")
statusERROR=$(cw.cecho error "ERROR")
sPre="    "

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

# Get a value from logfile (everything behind "=")
#
# global  string  $CW_LOGFILE  logfile of the cronjob
#
# param   string  label to search for
function getLogValue(){
        grep "^$1=" "$CW_LOGFILE" | cut -f 2- -d "="
}

# Get logfiles of all cronwrapper cronjobs
# No parameter is needed.
#
# global  string  $CW_LOGDIR  directory where the logfiles are stored
function getLogfiles(){
        ls -1t "$CW_LOGDIR"/*log | grep -Fv "/__"        
}

# Get logfiles of all cronwrapper cronjobs
# No parameter is needed.
function _getLabel(){
        echo "$1" | rev | cut -f 1- -d '/' | rev | cut -f 2- -d '_' | sed "s,\.log.*,," 
}

# Get logfiles of all cronwrapper cronjobs
# No parameter is needed.
#
# global  string  $CW_LOGDIR  directory where the logfiles are stored
function getRunningfiles(){
        ls -1t "$CW_LOGDIR"/*log.running* 2>/dev/null
}

# show introblock
# No parameter is needed.
#
# global  string  $sCurrentServer  name of local machine
# global  string  $_version        version number of this script
# global  string  $line1           line
function showIntroblock(){
        cw.color head
        cat <<ENDOFHEAD
$line1


  AXELS CRONWRAPPER
  Jobstatus of cronjobs on $( cw.emoji "🖥️" )${sCurrentServer}
$( printf "%78s" "v $_version" )
$line1
ENDOFHEAD
        cw.color reset
}

# Show help
#
# global  string  $CW_LOGDIR  directory where the logfiles are stored
#
# param   string  optional: info or error message
function showhelp(){
        local _self; _self="$( basename $0 )"
        showIntroblock
        echo "

Show the status of all local cronjobs that use the cronwrapper or a single job
by giving its logfile as parameter.

This script is part of Axels Cronwrapper.
  $( cw.emoji "📜" )License: GNU GPL 3.0
  $( cw.emoji "📗" )Docs   : https://www.axel-hahn.de/docs/cronwrapper/

$(cw.helpsection "✨" "SYNTAX")

  $_self [OPTIONS] [LOGFILE|LABEL]

$(cw.helpsection "🔧" "OPTIONS")

  -h|--help        show this help and exit.

  -d|--nodetails   hide detailed meta infos
  -i|--nointro     hide starting header
  -l|--nolast      hide last executions
  -o|--nooutput    hide logfile output (when adding a param for logfile|label)
  -r|--norunning   hide running processes
  -s|--short       short status; sortcut for '-d -i -l -r'

$(cw.helpsection "🏷️" "PARAMETERS")

  LOGFILE  filename to show details of a single logfile
  LABEL    label of a job

  Default: without any logfile/ label you get a total overview of all
           cronjobs.

$(cw.helpsection "🧩" "EXAMPLES")

  $_self
           show total overview over all jobs

  $_self -s
           Show tiny status for all jobs without intro header or details

  $_self myjob
           show output of a single job

  $_self $CW_LOGDIR/myjobfile.log
           show output of a single job

"
}

# show last executions of the same job in the last few days (*done files)
#
# global  string  $CW_LOGDIR    directory where the logfiles are stored
# global  string  $statusERROR  short status for error
# global  string  $statusOK     short status for OK
# global  string  $sPre         prefix spacing for output
#
# param  string  label
function _showLast(){
        local _label="$1"

        local iStart
        local iRc
        local iExectime
        local sStatus
        local line

        local iCount; typeset -i iCount; iCount=$( cat $CW_LOGDIR/*done | grep -c "job=${_label}:" )
        echo
        if [ "$iCount" -gt "1" ]; then
                echo "${sPre}Last executions:"
                echo
                echo "${sPre}${sPre}Result      Start time             rc    Execution time"
                echo "${sPre}${sPre}---------   -------------------   ---   ---------------"
                grep "job=${_label}:" $CW_LOGDIR/*done \
                        | tr ":" " " \
                        | sort -k +5 -r | head -10 \
                        | while read -r line
                do
                        iStart=$(    echo "$line" | grep -o "start=[0-9]*"    | cut -f 2 -d "=")
                        iExectime=$( echo "$line" | grep -o "exectime=[0-9]*" | cut -f 2 -d "=")
                        iRc=$(       echo "$line" | grep -o "rc=[0-9]*"       | cut -f 2 -d "=")
                        # echo "    $line"

                        ico=
                        test "$iRc" = "0" && sStatus=$statusOK
                        test "$iRc" = "0" || sStatus=$statusERROR
                        printf "${sPre}${sPre}%-17s %21s %5s  %13s s\n" "$sStatus" "$( date +%Y-%m-%d\ %H:%M:%S --date=@$iStart )" "$iRc" "$iExectime"
                done
        else
                echo "${sPre}(no other executions found)"
        fi
} 

# show status of a single sob
#
# global  string  $CW_LABELSTR     label of the cronjob
# global  string  $CW_LOGDIR       directory where the logfiles are stored
# global  string  $CW_LOGFILE      logfile of the cronjob
# global  string  $NO_COLOR        no color output
# global  string  $sCurrentServer  name of local machine
# global  integer $iMaxAge         current time in sec (Unix timestamp)
# global  string  $statusERROR     short status for error
# global  string  $statusOK        short status for OK
# global  string  $sPre            prefix spacing for output
# global  string  $bShowDetails    show details if <> 0
# global  string  $bShowHistory    show history of last executions if <> 0
#
# param   string  filename of cronwrapper logfile OR label of cronjob
# param   bool    flag: show logfile content; default: empty (=do not sohow log)
function showStatus(){
        local _label="$1"

        local iErr
        local _showlog
        local sCmd
        local sLastStart
        local iJobExpire
        local rc
        local iExectime
        local sTTL
        local sServer
        local sFqdnCheck
        local sServerCheck
        local statusRc
        local iTTL
        local iTTLsec
        local statusTtl
        local statusExpire
        local _jobstatus

        test -f "$_label" && CW_LOGFILE="$_label"
        test -f "$_label" || CW_LOGFILE="$CW_LOGDIR/$( hostname -f )_${_label}.log"

        CW_LABELSTR=$( _getLabel "$CW_LOGFILE")

        if [ ! -f "$CW_LOGFILE" ]; then
                echo
                cw.cecho "error" "ERROR: Wrong logfile / label was given."
                echo
                exit 1
        fi
        _showlog="${2:-}"

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

        if test "$CW_REQUIREFQDN" != "0" && ! echo "$sServer" | grep -q "\."; then
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

        if [ $iErr -gt 0 ]; then
                _jobstatus=$(cw.cecho "error" "$( cw.emoji "❌" )FAILED")
                iErrJobs=$iErrJobs+1
        else
                _jobstatus=$(cw.cecho "ok" "$( cw.emoji "✔️" )OK")
        fi
        if [ $bShowDetails -ne 0 ]; then
                echo    
                echo -n "..... $_jobstatus"
                echo ": $CW_LABELSTR"
                echo

                echo "${sPre}Command   : ${sCmd}"
                echo "${sPre}Last start: ${sLastStart}"
                echo "${sPre}Returncode: ${rc} ${statusRc}"
                if [ $rc -ne 0 ]; then
                        echo
                        echo "${sPre}${sPre}Last lines in output:"
                        getLogValue SCRIPTOUT | tail -20 | sed "s#^#${sPre}${sPre}#g"
                        echo
                fi
                echo "${sPre}Duration  : ${iExectime} s"
                echo "${sPre}Ttl       : ${statusTtl}"
                echo "${sPre}Expires   : ${iJobExpire} ${statusExpire}"
                test -n "${sFqdnCheck}"   && cw.cecho "warning" "${sPre}${sFqdnCheck}"
                test -n "${sServerCheck}" && cw.cecho "warning" "${sPre}${sServerCheck}"


                echo
                echo "${sPre}Logfile   : $CW_LOGFILE"
        else
                echo "$_jobstatus: $CW_LABELSTR"
        fi

        if [ -n "$_showlog" ] && [ "$bShowLogfile" -ne "0" ]; then
                (
                if [ "$NO_COLOR" != "1" ]; then
                        cat "$CW_LOGFILE" \
                        | sed -e "s/^REM.*/$(          printf "\033[0;36m&\033[0m" )/g" \
                                -e "s/^[A-Z]*/$(       printf "\033[0;35m&\033[0m" )/g" \
                                -e "s/=/$(             printf "\033[0;34m&\033[0m" )/g" \
                                -e "s/----- HOOK.*$/$( printf "\033[0;36m&\033[0m" )/g"
                else
                        cat "$CW_LOGFILE" 
                fi 
                ) | sed "s/^/${sPre}${sPre}/g"              
                echo "${sPre}Logfile   : $CW_LOGFILE"
        fi

        if [ "$bShowHistory" -ne "0" ]; then
                _showLast "$CW_LABELSTR"
        fi
}

# Show running jobs
# No parameter is needed.
#
# global  string  $CW_LABELSTR  label of the cronjob
# global  string  $CW_LOGFILE   logfile of the cronjob
# global  string  $statusERROR  short status for error
# global  string  $sPre         prefix spacing for output
#
function showRunningJobs(){
        local sCmd
        local sLastStart
        local iSince
        local iTTL
        local iPid
        local statusTtl
        if getRunningfiles >/dev/null 2>&1 ; then
                echo $line1
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
                        fi

                        echo
                        cw.cecho "head" "..... $( cw.emoji "⏳" )for $iSince min - $CW_LABELSTR"
                        echo
                        echo "${sPre}Logfile   : $CW_LOGFILE"
                        typeset -i iPid; iPid=$(getLogValue SCRIPTPROCESS)
                        if [ $iPid -gt 0 ]; then
                                # detect process id and check if it is still running
                                if ps $iPid >/dev/null 2>&1; then
                                        cw.cecho "ok" "${sPre}OK - still running"
                                else
                                        cw.cecho "error" "${sPre}ERROR     : The process $iPid does not exist anymore. The job was aborted."
                                        cw.cecho "error" "${sPre}            Check the log file and delete it."
                                fi
                        fi

                        echo "${sPre}command   : ${sCmd}"
                        echo "${sPre}last start: ${sLastStart}"
                        echo "${sPre}ttl       : ${iTTL} min"
                        echo
                done
        else
                echo
                echo "There is no running job."
        fi
}

# show total overview of all jobs
#
# global  string  $bShowDetails  show details if <> 0
# global  string  $bShowRunning  show running jobs if <> 0
# global  integer $iErrJobs      number of errors
#
# No parameter is needed.
function showTotalstatus(){
        local _logfile

        for _logfile in $( getLogfiles )
        do
                showStatus "$_logfile"
        done

        test "$bShowRunning" -ne "0" && showRunningJobs

        test "$bShowDetails" -ne "0" && (
                echo $line1
                echo "JOBS: $(getLogfiles | wc -l ) .. RUNNING: $(getRunningfiles | wc -l ) .. ERRORS: $iErrJobs"
                echo
        )

}
# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

sCurrentServer=$(hostname -f)

while [[ "$#" -gt 0 ]]; do case $1 in
    -h|--help) showhelp; exit 0;;

    -i|--nointro)   bShowHead=0; shift;;
    -d|--nodetails) bShowDetails=0; shift;;
    -l|--nolast)    bShowHistory=0; shift;;
    -o|--nooutput)  bShowLogfile=0; shift;;
    -r|--norunning) bShowRunning=0; shift;;
    -s|--short)     bShowHead=0; bShowHistory=0; bShowDetails=0; bShowRunning=0; shift;;
    *) if grep "^-" <<< "$1" >/dev/null ; then
        echo; echo "ERROR: Unknown parameter: $1"; echo; showhelp; exit 2
       fi
       break;
       ;;
esac; done

test "$bShowHead" -eq "1" && showIntroblock
if [ -n "${1:-}" ]; then
        showStatus "$1" 1
        echo
else
        showTotalstatus
fi
exit $iErrJobs

# ----------------------------------------------------------------------
